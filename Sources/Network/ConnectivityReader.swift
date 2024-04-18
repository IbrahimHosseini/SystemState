//
//  ConnectivityReader.swift
//
//
//  Created by Ibrahim on 4/18/24.
//

import SystemKit
import AppKit

internal class ConnectivityReaderWrapper {
    weak var reader: ConnectivityReader?
    
    init(_ reader: ConnectivityReader) {
        self.reader = reader
    }
}

// inspired by https://github.com/samiyr/SwiftyPing
internal class ConnectivityReader: Reader<NetworkConnectivity> {
    private let variablesQueue = DispatchQueue(label: "eu.exelban.ConnectivityReaderQueue")
    
    private let identifier = UInt16.random(in: 0..<UInt16.max)
    private var fingerprint: UUID = UUID()
    
    private var host: String {
        Store.shared.string(key: "Network_ICMPHost", defaultValue: "1.1.1.1")
    }
    private var lastHost: String = ""
    private var addr: Data? = nil
    private let timeout: TimeInterval = 5
    
    private var socket: CFSocket?
    private var socketSource: CFRunLoopSource?
    
    private var wrapper: NetworkConnectivity = NetworkConnectivity(status: false)
    
    private var _status: Bool? = nil
    private var status: Bool? {
        get {
            self.variablesQueue.sync { self._status }
        }
        set {
            self.variablesQueue.sync { self._status = newValue }
        }
    }
    
    private var _timeoutTimer: Timer?
    private var timeoutTimer: Timer? {
        get {
            self.variablesQueue.sync { self._timeoutTimer }
        }
        set {
            self.variablesQueue.sync { self._timeoutTimer = newValue }
        }
    }
    
    private var _isPinging: Bool = false
    private var isPinging: Bool {
        get {
            self.variablesQueue.sync { self._isPinging }
        }
        set {
            self.variablesQueue.sync { self._isPinging = newValue }
        }
    }
    
    private var _latency: Double? = nil
    private var latency: Double? {
        get {
            self.variablesQueue.sync { self._latency }
        }
        set {
            self.variablesQueue.sync { self._latency = newValue }
        }
    }
    
    var start: DispatchTime? = nil
    
    private struct ICMPHeader {
        public var type: UInt8
        public var code: UInt8
        public var checksum: UInt16
        public var identifier: UInt16
        public var sequenceNumber: UInt16
        public var payload: uuid_t
    }
    
    private struct IPHeader {
        public var versionAndHeaderLength: UInt8
        public var differentiatedServices: UInt8
        public var totalLength: UInt16
        public var identification: UInt16
        public var flagsAndFragmentOffset: UInt16
        public var timeToLive: UInt8
        public var `protocol`: UInt8
        public var headerChecksum: UInt16
        public var sourceAddress: (UInt8, UInt8, UInt8, UInt8)
        public var destinationAddress: (UInt8, UInt8, UInt8, UInt8)
    }
    
    override func setup() {
        self.interval = 1
        self.addr = self.resolve()
        self.openConn()
        self.read()
    }
    
    deinit {
        self.closeConn()
    }
    
    override func read() {
        guard !self.host.isEmpty else {
            if self.socket != nil {
                self.closeConn()
            }
            return
        }
        
        if self.socket == nil {
            self.setup()
        }
        
        if self.lastHost != self.host {
            self.addr = self.resolve()
        }
        
        guard !self.isPinging && self.active, let socket = self.socket, let addr = self.addr, let data = self.request() else { return }
        self.isPinging = true
        
        let timer = Timer(timeInterval: self.timeout, target: self, selector: #selector(self.timeoutCallback), userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: .common)
        self.timeoutTimer = timer
        self.start = DispatchTime.now()
        
        let error = CFSocketSendData(socket, addr as CFData, data as CFData, self.timeout)
        if error != .success {
            self.socketCallback(data: nil, error: error)
        }
        
        if let v = self.status {
            self.wrapper.status = v
            if let l = self.latency {
                self.wrapper.latency = l
            }
            self.callback(self.wrapper)
        }
    }
    
    @objc private func timeoutCallback() {
        self.status = false
        self.isPinging = false
    }
    
    private func socketCallback(data: Data? = nil, error: CFSocketError? = nil) {
        guard let data = data, validateResponse(data) else { return }
        let end = DispatchTime.now()
        
        self.latency = Double(end.uptimeNanoseconds - (self.start?.uptimeNanoseconds ?? 0)) / 1_000_000
        self.status = error == nil
        self.isPinging = false
        self.timeoutTimer?.invalidate()
        self.timeoutTimer = nil
    }
    
    // MARK: - helpers
    
    private func validateResponse(_ data: Data) -> Bool {
        guard data.count >= MemoryLayout<ICMPHeader>.size + MemoryLayout<IPHeader>.size,
              let headerOffset = icmpHeaderOffset(of: data) else { return false }
        
        let payloadSize = data.count - headerOffset - MemoryLayout<ICMPHeader>.size
        let icmpHeader = data.withUnsafeBytes({ $0.load(fromByteOffset: headerOffset, as: ICMPHeader.self) })
        let payload = data.subdata(in: (data.count - payloadSize)..<data.count)
        let uuid = UUID(uuid: icmpHeader.payload)
        
        guard uuid == self.fingerprint else { return false }
        guard icmpHeader.checksum == computeChecksum(header: icmpHeader, additionalPayload: [UInt8](payload)) else { return false }
        guard icmpHeader.type == 0 else { return false }
        guard icmpHeader.code == 0 else { return false }
        
        return true
    }
    
    private func request() -> Data? {
        var header = ICMPHeader(
            type: 8,
            code: 0,
            checksum: 0,
            identifier: CFSwapInt16HostToBig(self.identifier),
            sequenceNumber: CFSwapInt16HostToBig(0),
            payload: self.fingerprint.uuid
        )
        
        let delta = MemoryLayout<uuid_t>.size - MemoryLayout<uuid_t>.size
        var additional = [UInt8]()
        if delta > 0 {
            additional = (0..<delta).map { _ in UInt8.random(in: UInt8.min...UInt8.max) }
        }
        
        guard let checksum = computeChecksum(header: header, additionalPayload: additional) else { return nil }
        header.checksum = checksum
        
        return Data(bytes: &header, count: MemoryLayout<ICMPHeader>.size) + Data(additional)
    }
    
    private func computeChecksum(header: ICMPHeader, additionalPayload: [UInt8]) -> UInt16? {
        let typecode = Data([header.type, header.code]).withUnsafeBytes { $0.load(as: UInt16.self) }
        var sum = UInt64(typecode) + UInt64(header.identifier) + UInt64(header.sequenceNumber)
        let payload = convert(payload: header.payload) + additionalPayload
        guard payload.count % 2 == 0 else { return nil }
        
        var i = 0
        while i < payload.count {
            guard payload.indices.contains(i + 1) else { return nil }
            sum += Data([payload[i], payload[i + 1]]).withUnsafeBytes { UInt64($0.load(as: UInt16.self)) }
            i += 2
        }
        while sum >> 16 != 0 {
            sum = (sum & 0xffff) + (sum >> 16)
        }
        guard sum < UInt16.max else { return nil }
        
        return ~UInt16(sum)
    }
    
    private func convert(payload: uuid_t) -> [UInt8] {
        let p = payload
        return [p.0, p.1, p.2, p.3, p.4, p.5, p.6, p.7, p.8, p.9, p.10, p.11, p.12, p.13, p.14, p.15].map { UInt8($0) }
    }
    
    private func icmpHeaderOffset(of packet: Data) -> Int? {
        if packet.count >= MemoryLayout<IPHeader>.size + MemoryLayout<ICMPHeader>.size {
            let ipHeader = packet.withUnsafeBytes({ $0.load(as: IPHeader.self) })
            if ipHeader.versionAndHeaderLength & 0xF0 == 0x40 && ipHeader.protocol == IPPROTO_ICMP {
                let headerLength = Int(ipHeader.versionAndHeaderLength) & 0x0F * MemoryLayout<UInt32>.size
                if packet.count >= headerLength + MemoryLayout<ICMPHeader>.size {
                    return headerLength
                }
            }
        }
        return nil
    }
    
    private func openConn() {
        let info = ConnectivityReaderWrapper(self)
        let unmanagedSocketInfo = Unmanaged.passRetained(info)
        var context = CFSocketContext(version: 0, info: unmanagedSocketInfo.toOpaque(), retain: nil, release: nil, copyDescription: nil)
        self.socket = CFSocketCreate(kCFAllocatorDefault, AF_INET, SOCK_DGRAM, IPPROTO_ICMP, CFSocketCallBackType.dataCallBack.rawValue, { _, callBackType, _, data, info in
            guard let info = info, let data = data else { return }
            if (callBackType as CFSocketCallBackType) == CFSocketCallBackType.dataCallBack {
                let cfdata = Unmanaged<CFData>.fromOpaque(data).takeUnretainedValue()
                let wrapper = Unmanaged<ConnectivityReaderWrapper>.fromOpaque(info).takeUnretainedValue()
                wrapper.reader?.socketCallback(data: cfdata as Data)
            }
        }, &context)
        let handle = CFSocketGetNative(self.socket)
        var value: Int32 = 1
        let err = setsockopt(handle, SOL_SOCKET, SO_NOSIGPIPE, &value, socklen_t(MemoryLayout.size(ofValue: value)))
        guard err == 0 else { return }
        self.socketSource = CFSocketCreateRunLoopSource(nil, self.socket, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), self.socketSource, .commonModes)
    }
    
    private func closeConn() {
        if let source = self.socketSource {
            CFRunLoopSourceInvalidate(source)
            self.socketSource = nil
        }
        if let socket = self.socket {
            CFSocketInvalidate(socket)
            self.socket = nil
        }
        self.timeoutTimer?.invalidate()
        self.timeoutTimer = nil
    }
    
    private func resolve() -> Data? {
        self.lastHost = self.host
        var streamError = CFStreamError()
        let cfhost = CFHostCreateWithName(nil, self.host as CFString).takeRetainedValue()
        let status = CFHostStartInfoResolution(cfhost, .addresses, &streamError)
        guard status else { return nil }
        var success: DarwinBoolean = false
        guard let addresses = CFHostGetAddressing(cfhost, &success)?.takeUnretainedValue() as? [Data] else {
            return nil
        }
        var data: Data?
        for address in addresses {
            let addrin = address.socketAddress
            if address.count >= MemoryLayout<sockaddr>.size && addrin.sa_family == UInt8(AF_INET) {
                data = address
                break
            }
        }
        guard let data = data, !data.isEmpty else { return nil }
        return data
    }
}

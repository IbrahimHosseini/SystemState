//
//  File.swift
//  
//
//  Created by Ibrahim on 4/18/24.
//

import AppKit
import SystemKit
import SystemConfiguration
import CoreWLAN

internal class UsageReader: Reader<NetworkUsage> {
    private var reachability: Reachability = Reachability(start: true)
    private let variablesQueue = DispatchQueue(label: "eu.exelban.NetworkUsageReader")
    private var _usage: NetworkUsage = NetworkUsage()
    public var usage: NetworkUsage {
        get {
            self.variablesQueue.sync { self._usage }
        }
        set {
            self.variablesQueue.sync { self._usage = newValue }
        }
    }
    
    private var primaryInterface: String {
        get {
            if let global = SCDynamicStoreCopyValue(nil, "State:/Network/Global/IPv4" as CFString), let name = global["PrimaryInterface"] as? String {
                return name
            }
            return ""
        }
    }
    
    private var interfaceID: String {
        get {
            return Store.shared.string(key: "Network_interface", defaultValue: self.primaryInterface)
        }
        set {
            Store.shared.set(key: "Network_interface", value: newValue)
        }
    }
    
    private var reader: String {
        get {
            return Store.shared.string(key: "Network_reader", defaultValue: "interface")
        }
    }
    
    private var vpnConnection: Bool {
        if let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any], let scopes = settings["__SCOPED__"] as? [String: Any] {
            return !scopes.filter({ $0.key.contains("tap") || $0.key.contains("tun") || $0.key.contains("ppp") || $0.key.contains("ipsec") || $0.key.contains("ipsec0")}).isEmpty
        }
        return false
    }
    
    private var VPNMode: Bool {
        get {
            return Store.shared.bool(key: "Network_VPNMode", defaultValue: false)
        }
    }
    
    public override func setup() {
        self.reachability.reachable = {
            if self.active {
                self.getDetails()
            }
        }
        self.reachability.unreachable = {
            if self.active {
                self.usage.reset()
                self.callback(self.usage)
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshPublicIP), name: .refreshPublicIP, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resetTotalNetworkUsage), name: .resetTotalNetworkUsage, object: nil)
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1) {
            if self.active {
                self.getDetails()
            }
        }
    }
    
    public override func terminate() {
        self.reachability.stop()
    }
    
    public override func read() {
        let current: Bandwidth = self.reader == "interface" ? self.readInterfaceBandwidth() : self.readProcessBandwidth()
        
        // allows to reset the value to 0 when first read
        if self.usage.bandwidth.upload != 0 {
            self.usage.bandwidth.upload = current.upload - self.usage.bandwidth.upload
        }
        if self.usage.bandwidth.download != 0 {
            self.usage.bandwidth.download = current.download - self.usage.bandwidth.download
        }
        
        self.usage.bandwidth.upload = max(self.usage.bandwidth.upload, 0) // prevent negative upload value
        self.usage.bandwidth.download = max(self.usage.bandwidth.download, 0) // prevent negative download value
        
        self.usage.total.upload += self.usage.bandwidth.upload
        self.usage.total.download += self.usage.bandwidth.download
        
        self.usage.status = self.reachability.isReachable
        
        if self.vpnConnection && self.VPNMode {
            self.usage.bandwidth.upload /= 2
            self.usage.bandwidth.download /= 2
        }
        
        self.callback(self.usage)
        
        self.usage.bandwidth.upload = current.upload
        self.usage.bandwidth.download = current.download
    }
    
    private func readInterfaceBandwidth() -> Bandwidth {
        var interfaceAddresses: UnsafeMutablePointer<ifaddrs>? = nil
        var totalUpload: Int64 = 0
        var totalDownload: Int64 = 0
        guard getifaddrs(&interfaceAddresses) == 0 else {
            return Bandwidth()
        }
        
        var pointer = interfaceAddresses
        while pointer != nil {
            defer { pointer = pointer?.pointee.ifa_next }
            
            if String(cString: pointer!.pointee.ifa_name) != self.interfaceID {
                continue
            }
            
            if let ip = getLocalIP(pointer!), self.usage.localAddress != ip {
                self.usage.localAddress = ip
            }
            
            if let info = getBytesInfo(pointer!) {
                totalUpload += info.upload
                totalDownload += info.download
            }
        }
        freeifaddrs(interfaceAddresses)
        
        return Bandwidth(upload: totalUpload, download: totalDownload)
    }
    
    private func readProcessBandwidth() -> Bandwidth {
        let task = Process()
        task.launchPath = "/usr/bin/nettop"
        task.arguments = ["-P", "-L", "1", "-n", "-k", "time,interface,state,rx_dupe,rx_ooo,re-tx,rtt_avg,rcvsize,tx_win,tc_class,tc_mgt,cc_algo,P,C,R,W,arch"]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        defer {
            outputPipe.fileHandleForReading.closeFile()
            errorPipe.fileHandleForReading.closeFile()
        }
        
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        do {
            try task.run()
        } catch let err {
            error("read bandwidth from processes: \(err)", log: self.log)
            return Bandwidth()
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)
        _ = String(decoding: errorData, as: UTF8.self)
        
        if output.isEmpty {
            return Bandwidth()
        }

        var totalUpload: Int64 = 0
        var totalDownload: Int64 = 0
        var firstLine = false
        output.enumerateLines { (line, _) -> Void in
            if !firstLine {
                firstLine = true
                return
            }
            
            let parsedLine = line.split(separator: ",")
            guard parsedLine.count >= 3 else {
                return
            }
            
            if let download = Int64(parsedLine[1]) {
                totalDownload += download
            }
            if let upload = Int64(parsedLine[2]) {
                totalUpload += upload
            }
        }
        
        return Bandwidth(upload: totalUpload, download: totalDownload)
    }
    
    public func getDetails() {
        self.usage.reset()
        
        DispatchQueue.global(qos: .background).async {
            self.getPublicIP()
        }
        
        guard self.interfaceID != "" else { return }
        
        for interface in SCNetworkInterfaceCopyAll() as NSArray {
            if let bsdName = SCNetworkInterfaceGetBSDName(interface as! SCNetworkInterface), bsdName as String == self.interfaceID,
               let type = SCNetworkInterfaceGetInterfaceType(interface as! SCNetworkInterface),
               let displayName = SCNetworkInterfaceGetLocalizedDisplayName(interface as! SCNetworkInterface),
               let address = SCNetworkInterfaceGetHardwareAddressString(interface as! SCNetworkInterface) {
                self.usage.interface = NetworkInterface(displayName: displayName as String, BSDName: bsdName as String, address: address as String)
                
                switch type {
                case kSCNetworkInterfaceTypeEthernet:
                    self.usage.connectionType = .ethernet
                case kSCNetworkInterfaceTypeIEEE80211, kSCNetworkInterfaceTypeWWAN:
                    self.usage.connectionType = .wifi
                case kSCNetworkInterfaceTypeBluetooth:
                    self.usage.connectionType = .bluetooth
                default:
                    self.usage.connectionType = .other
                }
            }
        }
        
        guard self.usage.interface != nil else { return }
        
        if self.usage.connectionType == .wifi {
            if let interface = CWWiFiClient.shared().interface(withName: self.interfaceID) {
                self.usage.wifiDetails.ssid = interface.ssid()
                self.usage.wifiDetails.bssid = interface.bssid()
                self.usage.wifiDetails.countryCode = interface.countryCode()
                
                self.usage.wifiDetails.RSSI = interface.rssiValue()
                self.usage.wifiDetails.noise = interface.noiseMeasurement()
                self.usage.wifiDetails.transmitRate = interface.transmitRate()
                
                self.usage.wifiDetails.standard = interface.activePHYMode().description
                self.usage.wifiDetails.mode = interface.interfaceMode().description
                self.usage.wifiDetails.security = interface.security().description
                
                if let ch = interface.wlanChannel() {
                    self.usage.wifiDetails.channel = ch.description
                    
                    self.usage.wifiDetails.channelBand = ch.channelBand.description
                    self.usage.wifiDetails.channelWidth = ch.channelWidth.description
                    self.usage.wifiDetails.channelNumber = ch.channelNumber.description
                }
            }
            
            if self.usage.wifiDetails.ssid == nil || self.usage.wifiDetails.ssid == "" {
                let networksetupResponse = syncShell("networksetup -getairportnetwork \(self.interfaceID)")
                if networksetupResponse.split(separator: "\n").count == 1 {
                    let arr = networksetupResponse.split(separator: ":")
                    if let ssid = arr.last {
                        self.usage.wifiDetails.ssid = ssid.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    }
                }
            }
        }
    }
    
    private func getLocalIP(_ pointer: UnsafeMutablePointer<ifaddrs>) -> String? {
        var addr = pointer.pointee.ifa_addr.pointee
        
        guard addr.sa_family == UInt8(AF_INET) else {
            return nil
        }
        
        var ip = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        getnameinfo(&addr, socklen_t(addr.sa_len), &ip, socklen_t(ip.count), nil, socklen_t(0), NI_NUMERICHOST)
        
        return String(cString: ip)
    }
    
    private func getPublicIP() {
        struct Addr_s: Decodable {
            let ipv4: String?
            let ipv6: String?
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let response = syncShell("curl -s -4 https://api.serhiy.io/v1/stats/ip")
            if !response.isEmpty, let data = response.data(using: .utf8),
               let addr = try? JSONDecoder().decode(Addr_s.self, from: data) {
                if let ip = addr.ipv4, self.isIPv4(ip) {
                    self.usage.remoteAddress.v4 = ip
                }
            }
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let response = syncShell("curl -s -6 https://api.serhiy.io/v1/stats/ip")
            if !response.isEmpty, let data = response.data(using: .utf8),
               let addr = try? JSONDecoder().decode(Addr_s.self, from: data) {
                if let ip = addr.ipv6, !self.isIPv4(ip) {
                    self.usage.remoteAddress.v6 = ip
                }
            }
        }
    }
    
    private func getBytesInfo(_ pointer: UnsafeMutablePointer<ifaddrs>) -> (upload: Int64, download: Int64)? {
        let addr = pointer.pointee.ifa_addr.pointee
        
        guard addr.sa_family == UInt8(AF_LINK) else {
            return nil
        }
        
        let data: UnsafeMutablePointer<if_data>? = unsafeBitCast(pointer.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
        return (upload: Int64(data?.pointee.ifi_obytes ?? 0), download: Int64(data?.pointee.ifi_ibytes ?? 0))
    }
    
    private func isIPv4(_ ip: String) -> Bool {
        let arr = ip.split(separator: ".").compactMap{ Int($0) }
        return arr.count == 4 && arr.filter{ $0 >= 0 && $0 < 256}.count == 4
    }
    
    @objc func refreshPublicIP() {
        self.usage.remoteAddress.v4 = nil
        self.usage.remoteAddress.v6 = nil
        
        DispatchQueue.global(qos: .background).async {
            self.getPublicIP()
        }
    }
    
    @objc func resetTotalNetworkUsage() {
        self.usage.total = Bandwidth()
    }
}

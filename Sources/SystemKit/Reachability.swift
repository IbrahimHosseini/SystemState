//
//  Reachability.swift
//
//
//  Created by Ibrahim on 4/18/24.
//

import Foundation
import SystemConfiguration

public class Reachability {
    public var isReachable: Bool = false
    
    public var reachable: () -> Void = {}
    public var unreachable: () -> Void = {}
    
    private var isRunning = false
    private var reachability: SCNetworkReachability?
    private let reachabilitySerialQueue = DispatchQueue(label: "eu.exelban.ReachabilityQueue")
    private let log: NextLog = NextLog.shared.copy(category: "Reachability")
    
    public init(start: Bool = false) {
        var zeroAddress = sockaddr()
        zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zeroAddress.sa_family = sa_family_t(AF_INET)
        
        guard let ref = SCNetworkReachabilityCreateWithAddress(nil, &zeroAddress) else {
            error("SCNetworkReachability create with address")
            return
        }
        
        self.reachability = ref
        
        if start {
            self.start()
        }
    }
    
    public func start() {
        guard let reachability = self.reachability, !self.isRunning else {
            error("reachability is nil or already started")
            return
        }
        
        let callback: SCNetworkReachabilityCallBack = { (_, flags, info) in
            guard let info = info else { return }
            Unmanaged<Reachability>.fromOpaque(info).takeUnretainedValue().setFlags(flags)
        }
        
        var context = SCNetworkReachabilityContext(
            version: 0,
            info: Unmanaged<Reachability>.passUnretained(self).toOpaque(),
            retain: { (info: UnsafeRawPointer) -> UnsafeRawPointer in
                let unmanagedReachability = Unmanaged<Reachability>.fromOpaque(info)
                _ = unmanagedReachability.retain()
                return UnsafeRawPointer(unmanagedReachability.toOpaque())
            },
            release: { (info: UnsafeRawPointer) -> Void in
                Unmanaged<Reachability>.fromOpaque(info).release()
            },
            copyDescription: nil
        )
        
        guard SCNetworkReachabilitySetCallback(reachability, callback, &context) else {
            error("SCNetworkReachability set dispatch callback")
            self.stop()
            return
        }
        guard SCNetworkReachabilitySetDispatchQueue(reachability, reachabilitySerialQueue) else {
            error("SCNetworkReachability set dispatch queue")
            self.stop()
            return
        }
        
        self.reachabilitySerialQueue.sync { [unowned self] in
            guard let reachability = self.reachability else {
                error("reachability is nil")
                return
            }
            
            var flags = SCNetworkReachabilityFlags()
            if !SCNetworkReachabilityGetFlags(reachability, &flags) {
                error("SCNetworkReachability get flags")
                self.stop()
                return
            }
            
            self.setFlags(flags)
        }
        
        self.isRunning = true
    }
    
    public func stop() {
        defer { self.isRunning = false }
        guard let reachability = self.reachability, self.isRunning else {
            error("reachability is nil or already stopped")
            return
        }
        
        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
    }
    
    private func setFlags(_ flags: SCNetworkReachabilityFlags) {
        self.isReachable = flags.contains(.reachable)
        
        if self.isReachable {
            self.reachable()
        } else {
            self.unreachable()
        }
    }
}

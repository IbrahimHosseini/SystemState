//
//  NetworkInfo.swift
//
//
//  Created by Ibrahim on 4/18/24.
//

import SystemKit
import Module
import SystemConfiguration
import Foundation
import Common

public class NetworkInfo: Module {
    private var usageReader: UsageReader? = nil
    private var processReader: ProcessReader? = nil
    private var connectivityReader: ConnectivityReader? = nil
    
    private var processesInitialized: Bool = false
    private var base: StorageSizeBase {
        StorageSizeBase(rawValue: Store.shared.string(key: "Network_base", defaultValue: "byte")) ?? .byte
    }
    
    private let ipUpdater = NSBackgroundActivityScheduler(identifier: "eu.exelban.Stats.Network.IP")
    private let usageReseter = NSBackgroundActivityScheduler(identifier: "eu.exelban.Stats.Network.Usage")
    
    private var widgetActivationThreshold: Int {
        Store.shared.int(key: "\(self.config.name)_widgetActivationThreshold", defaultValue: 0) * 1_024
    }
    private var publicIPRefreshInterval: String {
        Store.shared.string(key: "\(self.name)_publicIPRefreshInterval", defaultValue: "never")
    }
    
    private var networkUsage: NetworkUsage?
    private var networkConnectivity: NetworkConnectivity?
    private var topProcess = [NetworkProcess]()
    private var uploadSpeed: Int64 = 0
    private var downloadSpeed: Int64 = 0
    
    // MARK: - public functions
    
    public override init() {
        
        super.init()
        
        guard self.available else { return }
        
        self.usageReader = UsageReader(.network) { [weak self] value in
            self?.usageCallback(value)
        }
        self.processReader = ProcessReader(.network) { [weak self] value in
            if let list = value {
                self?.processCallback(list)
            }
        }
        self.connectivityReader = ConnectivityReader(.network) { [weak self] value in
            self?.connectivityCallback(value)
        }
        
        self.numberOfProcessesUpdated()
        
        self.usageReader?.read()
        
        DispatchQueue.global(qos: .background).async {
            self.processReader?.read()
        }
        
        self.usageReader?.getDetails()
        
        self.setReaders([self.usageReader, self.processReader, self.connectivityReader])
        
        self.setIPUpdater()
        self.setUsageReset()
    }
    
    public override func isAvailable() -> Bool {
        var list: [String] = []
        for interface in SCNetworkInterfaceCopyAll() as NSArray {
            if let displayName = SCNetworkInterfaceGetLocalizedDisplayName(interface as! SCNetworkInterface) {
                list.append(displayName as String)
            }
        }
        return !list.isEmpty
    }
    
    /// System network information
    /// - Returns: an object the include the ``NetworkUsage`` information.
    public func getNetworkInfo() -> NetworkUsage? { networkUsage }
    
    /// Network connection state
    /// - Returns: an object the shown ``NetworkConnectivity`` information
    public func getNetworkConnectivity() -> NetworkConnectivity? { networkConnectivity }
    
    /// Network upload speed
    /// - Returns: a number that shown network upload speed
    public func getUploadSpeed() -> Int64 { uploadSpeed }
    
    /// Network download speed
    /// - Returns: a number that shown network download speed
    public func getDownloadSpeed() -> Int64 { downloadSpeed }
    
    /// Network top process
    /// - Returns: a list of ``NetworkProcess`` that shown which application use most from network.
    public func getTopProcess() -> [NetworkProcess] { topProcess }
    
    // MARK: - private functions
    
    private func setNetworkInfo(_ value: NetworkUsage) { networkUsage = value }
    
    private func setNetworkConnectivity(_ value: NetworkConnectivity) { networkConnectivity = value }
    
    private func setUploadSpeed(_ value: Int64) { uploadSpeed = value }
    
    private func setDownloadSpeed(_ value: Int64) { downloadSpeed = value }
    
    private func setTopProcess(_ value: [NetworkProcess]) { topProcess = value }
    
    private func numberOfProcessesUpdated() {
        self.processesInitialized = false
    }
    
    private func processCallback(_ list: [NetworkProcess]) {
        if processesInitialized { return }
        
        setTopProcess(list)
        
        let list = list.map{ $0 }
        
        for i in 0..<list.count {
            let process = list[i]
            let _ = Units(bytes: Int64(process.upload)).getReadableSpeed(base: self.base)
            let _ = Units(bytes: Int64(process.download)).getReadableSpeed(base: self.base)
        }
        
        self.processesInitialized = true
    }
    
    private func usageCallback(_ value: NetworkUsage?) {
        guard let value else { return }

        setNetworkInfo(value)
        
        // implement the upload and download speed
        if value.bandwidth.upload >= self.widgetActivationThreshold || value.bandwidth.download >= self.widgetActivationThreshold {
            
            setUploadSpeed(value.bandwidth.upload)
            
            setDownloadSpeed(value.bandwidth.download)
        }
    }
    
    private func connectivityCallback(_ value: NetworkConnectivity?) {
        guard let value else { return }
        
        setNetworkConnectivity(value)
    }
    
    private func setIPUpdater() {
        self.ipUpdater.invalidate()
        
        switch self.publicIPRefreshInterval {
        case "hour":
            self.ipUpdater.interval = 60 * 60
        case "12":
            self.ipUpdater.interval = 60 * 60 * 12
        case "24":
            self.ipUpdater.interval = 60 * 60 * 24
        default: return
        }
        
        self.ipUpdater.repeats = true
        self.ipUpdater.schedule { (completion: @escaping NSBackgroundActivityScheduler.CompletionHandler) in
            guard self.isAvailable() else {
                return
            }
            debug("going to automatically refresh IP address...")
            NotificationCenter.default.post(name: .refreshPublicIP, object: nil, userInfo: nil)
            completion(NSBackgroundActivityScheduler.Result.finished)
        }
    }
    
    private func setUsageReset() {
        self.usageReseter.invalidate()
        
        self.usageReseter.repeats = true
        self.usageReseter.schedule { (completion: @escaping NSBackgroundActivityScheduler.CompletionHandler) in
            guard self.isAvailable() else {
                return
            }
            
            debug("going to reset the usage...")
            NotificationCenter.default.post(name: .resetTotalNetworkUsage, object: nil, userInfo: nil)
            completion(NSBackgroundActivityScheduler.Result.finished)
        }
    }
    
}

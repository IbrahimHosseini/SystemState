//
//  Network.swift
//
//
//  Created by Ibrahim on 4/18/24.
//

import SystemKit
import Module
import SystemConfiguration
import Foundation

public class Network: Module {
    private var usageReader: UsageReader? = nil
    private var processReader: ProcessReader? = nil
    private var connectivityReader: ConnectivityReader? = nil
    
    private let ipUpdater = NSBackgroundActivityScheduler(identifier: "eu.exelban.Stats.Network.IP")
    private let usageReseter = NSBackgroundActivityScheduler(identifier: "eu.exelban.Stats.Network.Usage")
    
    private var widgetActivationThreshold: Int {
        Store.shared.int(key: "\(self.config.name)_widgetActivationThreshold", defaultValue: 0) * 1_024
    }
    private var publicIPRefreshInterval: String {
        Store.shared.string(key: "\(self.name)_publicIPRefreshInterval", defaultValue: "never")
    }
    
    public override init() {
        
        super.init()
        
        guard self.available else { return }
        
        self.usageReader = UsageReader(.network) { [weak self] value in
            self?.usageCallback(value)
        }
        self.processReader = ProcessReader(.network) { [weak self] value in
            if let list = value {
//                self?.popupView.processCallback(list)
            }
        }
        self.connectivityReader = ConnectivityReader(.network) { [weak self] value in
            self?.connectivityCallback(value)
        }
        
        /*self.settingsView.callbackWhenUpdateNumberOfProcesses = {
            self.popupView.numberOfProcessesUpdated()
            DispatchQueue.global(qos: .background).async {
                self.processReader?.read()
            }
        }
        
        self.settingsView.callback = { [weak self] in
            self?.usageReader?.getDetails()
            self?.usageReader?.read()
        }
        self.settingsView.usageResetCallback = { [weak self] in
            self?.setUsageReset()
        }
        self.settingsView.ICMPHostCallback = { [weak self] isDisabled in
            if isDisabled {
                self?.popupView.resetConnectivityView()
                self?.connectivityCallback(Network_Connectivity(status: false))
            }
        }
        self.settingsView.publicIPRefreshIntervalCallback = { [weak self] in
            self?.setIPUpdater()
        }*/
        
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
    
    private func usageCallback(_ value: NetworkUsage?) {
        guard let value else { return }
        
//        self.popupView.usageCallback(value)
//        self.portalView.usageCallback(value)
        
        var upload: Int64 = 0
        var download: Int64 = 0
        if value.bandwidth.upload >= self.widgetActivationThreshold || value.bandwidth.download >= self.widgetActivationThreshold {
            upload = value.bandwidth.upload
            download = value.bandwidth.download
        }
        
//        self.menuBar.widgets.filter{ $0.isActive }.forEach { (w: Widget) in
//            switch w.item {
//            case let widget as SpeedWidget: widget.setValue(upload: upload, download: download)
//            case let widget as NetworkChart: widget.setValue(upload: Double(upload), download: Double(download))
//            default: break
//            }
//        }
    }
    
    private func connectivityCallback(_ value: NetworkConnectivity?) {
        guard let value else { return }
        
//        self.popupView.connectivityCallback(value)
        
//        self.menuBar.widgets.filter{ $0.isActive }.forEach { (w: Widget) in
//            switch w.item {
//            case let widget as StateWidget: widget.setValue(value.status)
//            default: break
//            }
//        }
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
        
//        switch AppUpdateInterval(rawValue: Store.shared.string(key: "\(self.config.name)_usageReset", defaultValue: AppUpdateInterval.atStart.rawValue)) {
//        case .oncePerDay: self.usageReseter.interval = 60 * 60 * 24
//        case .oncePerWeek: self.usageReseter.interval = 60 * 60 * 24 * 7
//        case .oncePerMonth: self.usageReseter.interval = 60 * 60 * 24 * 30
//        case .never, .atStart: return
//        default: return
//        }
        
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

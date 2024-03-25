//
//  Battery.swift
//
//
//  Created by Ibrahim on 3/14/24.
//

import AppKit
import SystemKit
import Module

public class Battery: Module {
    
    private var usageReader: UsageReader? = nil
    private var processReader: ProcessReader? = nil
    
    private var lowLevelNotificationState: Bool = false
    private var highLevelNotificationState: Bool = false
    private var notificationID: String? = nil
    
    public var batteyInfo: BatteryInfoModel!
    public var topProcess = [TopProcess]()
    
    public override init() {
        
        super.init()
        guard self.available else { return }
        
        self.usageReader = UsageReader(.battery) { [weak self] value in
            self?.usageCallback(value)
        }
        self.processReader = ProcessReader(.battery) { [weak self] value in
            if let list = value {
                self?.processCallback(list)
            }
        }
        
        self.usageReader?.read()

        self.processReader?.read()
        
        self.setReaders([self.usageReader, self.processReader])
    }
    
    public override func isAvailable() -> Bool {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        return !sources.isEmpty
    }
    
    private func usageCallback(_ value: BatteryUsage?) {
        guard let value else { return }
        
        batteyInfo = BatteryInfoModel(
            level: value.level,
            cycles: value.cycles,
            health: value.health
        )
    }
    
    private func processCallback(_ list: [TopProcess]) {
        self.topProcess = list
    }

}


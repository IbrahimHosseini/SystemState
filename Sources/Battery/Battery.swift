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
    
    public var batteryInfo = ""
    
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
        
        let level = "\(Int(abs(value.level) * 100))%"
        let health = value.health
        let cycles = value.cycles
        
        batteryInfo = "Level: \(level), Health: \(health), Cycles: \(cycles)"
        
        print("""
            ===================BATTERY====================
            \(batteryInfo)
            """)
    }
    
    public func processCallback(_ list: [TopProcess]) {
        
        let mapList = list.map { $0 }
        
        for i in 0..<mapList.count {
            let process = mapList[i]
//            self.processes?.set(i, process, ["\(process.usage)%"])
            
            print("""
                    +++++ Process list:
                    process\(i) => id: \(process.pid), name: \(process.name), usage: \(process.usage)%
                """)
        }
        
    }

}


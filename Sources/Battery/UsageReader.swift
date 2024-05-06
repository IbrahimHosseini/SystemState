//
//  UsageReader.swift
//
//
//  Created by Ibrahim on 3/13/24.
//
#if os(macOS)
import AppKit
#endif
import SystemKit
import IOKit.ps

internal class UsageReader: Reader<BatteryUsage> {
    private var service: io_connect_t = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
    
    private var source: CFRunLoopSource?
    private var loop: CFRunLoop?
    
    private var usage: BatteryUsage = BatteryUsage()
    
    internal override func start() {
        self.active = true
        
        // Comment this section due to app crashing in our app
        
        /*
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        self.source = IOPSNotificationCreateRunLoopSource({ (context) in
            guard let ctx = context else {
                return
            }
            
            let watcher = Unmanaged<UsageReader>.fromOpaque(ctx).takeUnretainedValue()
            if watcher.active {
                watcher.read()
            }
        }, context).takeRetainedValue()
        
        self.loop = RunLoop.current.getCFRunLoop()
        CFRunLoopAddSource(self.loop, source, .defaultMode)
        */
        self.read()
    }
    
    internal override func stop() {
        guard let runLoop = loop, let source = source else {
            return
        }
        
        self.active = false
        CFRunLoopRemoveSource(runLoop, source, .defaultMode)
    }
    
    internal override func read() {
        let psInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let psList = IOPSCopyPowerSourcesList(psInfo).takeRetainedValue() as [CFTypeRef]
        
        if psList.isEmpty {
            return
        }
        
        for ps in psList {
            if let list = IOPSGetPowerSourceDescription(psInfo, ps).takeUnretainedValue() as? [String: Any] {
                self.usage.powerSource = list[kIOPSPowerSourceStateKey] as? String ?? "AC Power"
                self.usage.isBatteryPowered = self.usage.powerSource == "Battery Power"
                self.usage.isCharged = list[kIOPSIsChargedKey] as? Bool ?? false
                self.usage.isCharging = self.getBoolValue("IsCharging" as CFString) ?? false
                self.usage.optimizedChargingEngaged = list["Optimized Battery Charging Engaged"] as? Int == 1
                self.usage.level = Double(list[kIOPSCurrentCapacityKey] as? Int ?? 0) / 100
                
                if let time = list[kIOPSTimeToEmptyKey] as? Int {
                    self.usage.timeToEmpty = Int(time)
                }
                if let time = list[kIOPSTimeToFullChargeKey] as? Int {
                    self.usage.timeToCharge = Int(time)
                }
                
                if self.usage.powerSource == "AC Power" {
                    self.usage.timeOnACPower = Date()
                }
                
                self.usage.cycles = self.getIntValue("CycleCount" as CFString) ?? 0
                
                self.usage.currentCapacity = self.getIntValue("AppleRawCurrentCapacity" as CFString) ?? 0
                self.usage.designedCapacity = self.getIntValue("DesignCapacity" as CFString) ?? 1
                self.usage.maxCapacity = self.getIntValue((isARM ? "AppleRawMaxCapacity" : "MaxCapacity") as CFString) ?? 1
                if !isARM {
                    self.usage.state = list[kIOPSBatteryHealthKey] as? String
                }
                self.usage.health = Int((Double(100 * self.usage.maxCapacity) / Double(self.usage.designedCapacity)).rounded(.toNearestOrEven))
                
                self.usage.amperage = self.getIntValue("Amperage" as CFString) ?? 0
                self.usage.voltage = self.getVoltage() ?? 0
                self.usage.temperature = self.getTemperature() ?? 0
                
                var ACwatts: Int = 0
                if let ACDetails = IOPSCopyExternalPowerAdapterDetails() {
                    if let ACList = ACDetails.takeRetainedValue() as? [String: Any] {
                        guard let watts = ACList[kIOPSPowerAdapterWattsKey] else {
                            return
                        }
                        ACwatts = Int(watts as! Int)
                    }
                }
                self.usage.ACwatts = ACwatts
                
                self.callback(self.usage)
            }
        }
    }
    
    private func getBoolValue(_ forIdentifier: CFString) -> Bool? {
        if let value = IORegistryEntryCreateCFProperty(self.service, forIdentifier, kCFAllocatorDefault, 0) {
            return value.takeRetainedValue() as? Bool
        }
        return nil
    }
    
    private func getIntValue(_ identifier: CFString) -> Int? {
        if let value = IORegistryEntryCreateCFProperty(self.service, identifier, kCFAllocatorDefault, 0) {
            return value.takeRetainedValue() as? Int
        }
        return nil
    }
    
    private func getDoubleValue(_ identifier: CFString) -> Double? {
        if let value = IORegistryEntryCreateCFProperty(self.service, identifier, kCFAllocatorDefault, 0) {
            return value.takeRetainedValue() as? Double
        }
        return nil
    }
    
    private func getVoltage() -> Double? {
        if let value = self.getDoubleValue("Voltage" as CFString) {
            return value / 1000.0
        }
        return nil
    }
    
    private func getTemperature() -> Double? {
        if let value = IORegistryEntryCreateCFProperty(self.service, "Temperature" as CFString, kCFAllocatorDefault, 0) {
            return value.takeRetainedValue() as! Double / 100.0
        }
        return nil
    }
}

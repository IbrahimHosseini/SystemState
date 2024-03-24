//
//  Sensors.swift
//
//
//  Created by Ibrahim on 3/18/24.
//

import AppKit
import SystemKit
import Module
import SMC
import Common

public class Sensors: Module {
    private var sensorsReader: SensorsReader?
    
    private var fanValueState: FanValue {
        .percentage
    }
    
    private var tempratures = [SensorService]()
    
    public override init() {
        super.init()
        
        self.sensorsReader = SensorsReader { [weak self] value in
            self?.usageCallback(value)
        }
        
        self.sensorsReader?.read()
        
        self.sensorsReader?.setInterval(1)
        
        self.setReaders([self.sensorsReader])
    }
    
    private func usageCallback(_ value: SensorsListService?) {
        guard let value else { return }
        
        tempratures = value.sensors.filter { $0.type == .temperature }
        
        let cpuTempreture = tempratures.filter { $0.group == .CPU }.first?.value
        
        let gpuTempreture = tempratures.filter { $0.group == .GPU }.first?.value
        
        let storageTempreture = tempratures
            .filter { $0.group == .system && $0.name.hasPrefix("Disk") }
            .first?.value
    }
    
    public func temprator( _ type: ModuleType) -> Double? {
        switch type {
        case .storage:
            return tempratures.filter { $0.group == .system && $0.type == .temperature && $0.name.hasPrefix("Disk") }.first?.value

        case .network:
            return tempratures.filter { $0.group == .system && $0.type == .temperature && $0.name.hasPrefix("Airport") }.first?.value
            
        case .battery:
            let battery = tempratures.filter { $0.group == .system && $0.type == .temperature && $0.name.hasPrefix("Battery") }
            
            let sum = battery.map { $0.value }.reduce(0, { $0 + $1 })
                
            return sum/Double(battery.count)
            
        default: return 0
        
        }
    }
}

public struct StackModel: KeyValueHelper {
    public var key: String
    public var value: String
    public var additional: Any?
    
    var index: Int {
        get {
            Store.shared.int(key: "stack_\(self.key)_index", defaultValue: -1)
        }
        set {
            Store.shared.set(key: "stack_\(self.key)_index", value: newValue)
        }
    }
    
    public init(key: String, value: String, additional: Any? = nil) {
        self.key = key
        self.value = value
        self.additional = additional
    }
}

public enum FanValue {
    case rpm
    case percentage
}

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
//        FanValue(rawValue: Store.shared.string(key: "\(self.config.name)_fanValue", defaultValue: "percentage")) ??
        .percentage
    }
    
    public var sensoreInfo = ""
    
    public override init() {
        super.init()
        
        self.sensorsReader = SensorsReader { [weak self] value in
            print("value=> \(value?.sensors.map { $0.value})")
            self?.usageCallback(value)
        }
        
        self.sensorsReader?.read()
        
        self.sensorsReader?.setInterval(1)
        
//        DispatchQueue.global(qos: .background).async {
//            self.sensorsReader?.HIDCallback()
//        }
//        
//        DispatchQueue.global(qos: .background).async {
//            self.sensorsReader?.unknownCallback()
//        }
        
        self.setReaders([self.sensorsReader])
    }
    
//    private func checkIfNoSensorsEnabled() {
//        guard let reader = self.sensorsReader else { return }
//        if reader.list.sensors.filter({ $0.state }).isEmpty {
//            NotificationCenter.default.post(name: .toggleModule, object: nil, userInfo: ["module": self.config.name, "state": false])
//        }
//    }
    
    private func usageCallback(_ value: SensorsListService?) {
        guard let value else { return }
        
        var list: [StackModel] = []
        
        value.sensors.forEach { (s: SensorService) in
            if s.state {
                var value = s.formattedMiniValue
                
                if let f = s as? Fan {

                    if self.fanValueState == .percentage {
                        value = "\(f.percentage)%"
                    }
                }
                list.append(StackModel(key: s.key, value: value, additional: s.name))
            }
            sensoreInfo = "+++=== \(value.sensors.map { "Value: \($0.name), type: \($0.value)" })"
            print(sensoreInfo)
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

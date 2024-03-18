//
//  Fan.swift
//
//
//  Created by Ibrahim on 3/18/24.
//

import Foundation
import SMC
import SystemKit

public struct Fan: SensorService, Codable {
    public let id: Int
    public var key: String
    public var name: String
    public var minSpeed: Double
    public var maxSpeed: Double
    public var value: Double
    public var mode: FanMode
    
    public var percentage: Int {
        if self.value != 0 && self.maxSpeed != 0 && self.value != 1 && self.maxSpeed != 1 {
            return (100*Int(self.value)) / Int(self.maxSpeed)
        }
        return 0
    }
    
    public var group: SensorGroup = .sensor
    public var type: SensorType = .fan
    public var platforms: [Platform] = Platform.all
    public var isIntelOnly: Bool = false
    public var isComputed: Bool = false
    public var average: Bool = false
    public var unit: String = "RPM"
    
    public var formattedValue: String {
        "\(Int(self.value)) RPM"
    }
    public var formattedMiniValue: String {
        "\(Int(self.value))"
    }
    public var formattedPopupValue: String {
        "\(Int(self.value)) RPM"
    }
    public var localValue: Double {
        return self.value
    }
    
    public var state: Bool {
        Store.shared.bool(key: "sensor_\(self.key)", defaultValue: false)
    }
    public var popupState: Bool {
        Store.shared.bool(key: "sensor_\(self.key)_popup", defaultValue: true)
    }
    public var notificationThreshold: String {
        Store.shared.string(key: "sensor_\(self.key)_notification", defaultValue: "")
    }
    
    public var customSpeed: Int? {
        get {
            if !Store.shared.exist(key: "fan_\(self.id)_speed") {
                return nil
            }
            return Store.shared.int(key: "fan_\(self.id)_speed", defaultValue: Int(self.minSpeed))
        }
        set {
            if let value = newValue {
                Store.shared.set(key: "fan_\(self.id)_speed", value: value)
            } else {
                Store.shared.remove("fan_\(self.id)_speed")
            }
        }
    }
    public var customMode: FanMode? {
        get {
            if !Store.shared.exist(key: "fan_\(self.id)_mode") {
                return nil
            }
            let value = Store.shared.int(key: "fan_\(self.id)_mode", defaultValue: FanMode.automatic.rawValue)
            return FanMode(rawValue: value)
        }
        set {
            if let value = newValue {
                Store.shared.set(key: "fan_\(self.id)_mode", value: value.rawValue)
            } else {
                Store.shared.remove("fan_\(self.id)_mode")
            }
        }
    }
}

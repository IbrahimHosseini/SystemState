//
//  Sensor.swift
//
//
//  Created by Ibrahim on 3/18/24.
//

import SystemKit
import AppKit
import Module

public struct SensorModel: SensorService, Codable {
    public var key: String
    public var name: String
    
    public var value: Double = 0
    
    public var group: SensorGroup
    public var type: SensorType
    public var platforms: [Platform]
    public var isComputed: Bool = false
    public var average: Bool = false
    
    public var unit: String {
        switch self.type {
        case .temperature:
            return UnitTemperature.current.symbol
        case .voltage:
            return "V"
        case .power:
            return "W"
        case .energy:
            return "Wh"
        case .current:
            return "A"
        case .fan:
            return "RPM"
        }
    }
    
    public var formattedValue: String {
        switch self.type {
        case .temperature:
            return temperature(value)
        case .voltage:
            let val = value >= 100 ? "\(Int(value))" : String(format: "%.3f", value)
            return "\(val)\(unit)"
        case .power, .energy:
            let val = value >= 100 ? "\(Int(value))" : String(format: "%.2f", value)
            return "\(val)\(unit)"
        case .current:
            let val = value >= 100 ? "\(Int(value))" : String(format: "%.2f", value)
            return "\(val)\(unit)"
        case .fan:
            return "\(Int(value)) \(unit)"
        }
    }
    public var formattedPopupValue: String {
        switch self.type {
        case .temperature:
            return temperature(value, fractionDigits: 1)
        case .voltage:
            let val = value >= 100 ? "\(Int(value))" : String(format: "%.3f", value)
            return "\(val)\(unit)"
        case .power, .energy:
            let val = value >= 100 ? "\(Int(value))" : String(format: "%.2f", value)
            return "\(val)\(unit)"
        case .current:
            let val = value >= 100 ? "\(Int(value))" : String(format: "%.2f", value)
            return "\(val)\(unit)"
        case .fan:
            return "\(Int(value)) \(unit)"
        }
    }
    public var formattedMiniValue: String {
        switch self.type {
        case .temperature:
            return temperature(value).replacingOccurrences(of: "C", with: "").replacingOccurrences(of: "F", with: "")
        case .voltage, .power, .energy, .current:
            let val = value >= 9.95 ? "\(Int(round(value)))" : String(format: "%.1f", value)
            return "\(val)\(unit)"
        case .fan:
            return "\(Int(value))"
        }
    }
    public var localValue: Double {
        if self.type == .temperature {
            return Double(self.formattedMiniValue.digits) ?? self.value
        }
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
    
    public func copy() -> SensorModel {
        SensorModel(
            key: self.key,
            name: self.name,
            group: self.group,
            type: self.type,
            platforms: self.platforms,
            isComputed: self.isComputed,
            average: self.average
        )
    }
}

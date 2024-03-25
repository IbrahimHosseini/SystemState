//
//  BatteryUsage.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import SystemKit
import AppKit

internal struct BatteryUsage: value_t, Codable {
    var powerSource: String = ""
    var state: String? = nil
    var isCharged: Bool = false
    var isCharging: Bool = false
    var isBatteryPowered: Bool = false
    var optimizedChargingEngaged: Bool = false
    var level: Double = 0
    var cycles: Int = 0
    var health: Int = 0
    
    var designedCapacity: Int = 0
    var maxCapacity: Int = 0
    var currentCapacity: Int = 0
    
    var amperage: Int = 0
    var voltage: Double = 0
    var temperature: Double = 0
    
    var ACwatts: Int = 0
    
    var timeToEmpty: Int = 0
    var timeToCharge: Int = 0
    var timeOnACPower: Date? = nil
    
    public var widgetValue: Double {
        get {
            return self.level
        }
    }
}

//
//  MemoryUsage.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation
import SystemKit

public struct MemoryUsage: value_t, Codable {
    var total: Double
    var used: Double
    var free: Double
    
    var active: Double
    var inactive: Double
    var wired: Double
    var compressed: Double
    
    var app: Double
    var cache: Double
    var pressure: Double
    
    var rawPressureLevel: UInt
    var swap: SwapModel
    
    public var widgetValue: Double {
        get {
            return self.usage
        }
    }
    
    public var usage: Double {
        get {
            return Double((self.total - self.free) / self.total)
        }
    }
    
    public var pressureLevel: DispatchSource.MemoryPressureEvent {
        DispatchSource.MemoryPressureEvent(rawValue: self.rawPressureLevel)
    }
}

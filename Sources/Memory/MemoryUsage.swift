//
//  MemoryUsage.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation
import SystemKit

public struct MemoryUsage: value_t, Codable {
    public var total: Double
    public var used: Double
    public var free: Double
    
    public var active: Double
    public var inactive: Double
    public var wired: Double
    public var compressed: Double
    
    public var app: Double
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

public extension Double {
    var readableMemory: String {
        Units(bytes: Int64(self)).getReadableMemory()
    }
}

//
//  CPULoad.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import SystemKit

public struct CPULoad: value_t, Codable {
    var totalUsage: Double = 0
    var usagePerCore: [Double] = []
    var usageECores: Double? = nil
    var usagePCores: Double? = nil
    
    public var systemLoad: Double = 0
    public var userLoad: Double = 0
    public var idleLoad: Double = 0
    
    public var widgetValue: Double {
        get {
            return self.totalUsage
        }
    }
}

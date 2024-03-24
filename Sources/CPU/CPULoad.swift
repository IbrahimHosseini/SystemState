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
    
    var systemLoad: Double = 0
    var userLoad: Double = 0
    var idleLoad: Double = 0
    
    public var widgetValue: Double {
        get {
            return self.totalUsage
        }
    }
}

public extension Double {
    var showAsPercent: String {
        "\(Int(self.rounded(toPlaces: 2) * 100))%"
    }
}

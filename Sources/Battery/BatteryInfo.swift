//
//  File.swift
//  
//
//  Created by Ibrahim on 3/25/24.
//

import Foundation

public struct BatteryInfoModel {
    public let level: Double
    public let cycles: Int
    public let health: Int
    public let isCharging: Bool
    public let isBatteryPowered: Bool
    public let temperature: Double
}

//
//  SensorType.swift
//
//
//  Created by Ibrahim on 3/18/24.
//

import Foundation

public enum SensorType: String, Codable {
    case temperature = "Temperature"
    case voltage = "Voltage"
    case current = "Current"
    case power = "Power"
    case energy = "Energy"
    case fan = "Fans"
}

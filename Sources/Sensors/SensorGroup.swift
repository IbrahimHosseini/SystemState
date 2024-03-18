//
//  SensorGroup.swift
//
//
//  Created by Ibrahim on 3/18/24.
//

import Foundation

public enum SensorGroup: String, Codable {
    case CPU = "CPU"
    case GPU = "GPU"
    case system = "Systems"
    case sensor = "Sensors"
    case hid = "HID"
    case unknown = "Unknown"
}

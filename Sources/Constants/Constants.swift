//
//  Constants.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import AppKit
import Common

public let BatteryInfo: [KeyValueModel] = [
    KeyValueModel(key: "percentage", value: "Percentage"),
    KeyValueModel(key: "time", value: "Time"),
    KeyValueModel(key: "percentageAndTime", value: "Percentage and time"),
    KeyValueModel(key: "timeAndPercentage", value: "Time and percentage")
]


public struct Constants {
    public static let defaultProcessIcon = NSWorkspace.shared.icon(forFile: "/bin/bash")
}

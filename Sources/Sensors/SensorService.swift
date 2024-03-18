//
//  SensorService.swift
//  
//
//  Created by Ibrahim on 3/18/24.
//

import SystemKit

public protocol SensorService {
    var key: String { get }
    var name: String { get }
    var value: Double { get set }
    var state: Bool { get }
    var popupState: Bool { get }
    var notificationThreshold: String { get }
    
    var group: SensorGroup { get }
    var type: SensorType { get }
    var platforms: [Platform] { get }
    var isComputed: Bool { get }
    var average: Bool { get }
    
    var localValue: Double { get }
    var unit: String { get }
    var formattedValue: String { get }
    var formattedMiniValue: String { get }
    var formattedPopupValue: String { get }
}

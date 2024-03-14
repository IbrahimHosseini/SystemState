//
//  Notification.Name+extension.swift
//
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation

public extension Notification.Name {
    static let toggleSettings = Notification.Name("toggleSettings")
    static let toggleModule = Notification.Name("toggleModule")
    static let togglePopup = Notification.Name("togglePopup")
    static let toggleWidget = Notification.Name("toggleWidget")
    static let openModuleSettings = Notification.Name("openModuleSettings")
    static let clickInSettings = Notification.Name("clickInSettings")
    static let refreshPublicIP = Notification.Name("refreshPublicIP")
    static let resetTotalNetworkUsage = Notification.Name("resetTotalNetworkUsage")
    static let syncFansControl = Notification.Name("syncFansControl")
    static let fanHelperState = Notification.Name("fanHelperState")
    static let toggleOneView = Notification.Name("toggleOneView")
    static let widgetRearrange = Notification.Name("widgetRearrange")
    static let moduleRearrange = Notification.Name("moduleRearrange")
    static let pause = Notification.Name("pause")
    static let toggleFanControl = Notification.Name("toggleFanControl")
}

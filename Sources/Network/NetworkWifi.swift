//
//  NetworkWifi.swift
//
//
//  Created by Ibrahim on 4/18/24.
//

import Foundation

public struct NetworkWifi: Codable {
    var countryCode: String? = nil
    var ssid: String? = nil
    var bssid: String? = nil
    var RSSI: Int? = nil
    var noise: Int? = nil
    var transmitRate: Double? = nil
    
    var standard: String? = nil
    var mode: String? = nil
    var security: String? = nil
    var channel: String? = nil
    
    var channelBand: String? = nil
    var channelWidth: String? = nil
    var channelNumber: String? = nil
    
    mutating func reset() {
        self.countryCode = nil
        self.ssid = nil
        self.RSSI = nil
        self.noise = nil
        self.transmitRate = nil
        self.standard = nil
        self.mode = nil
        self.security = nil
        self.channel = nil
    }
    
}

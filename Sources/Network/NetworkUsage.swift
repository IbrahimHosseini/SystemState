//
//  NetworkUsage.swift
//
//
//  Created by Ibrahim on 4/18/24.
//

import Foundation
import SystemKit

public struct NetworkUsage: value_t, Codable {
    var bandwidth: Bandwidth = Bandwidth()
    var total: Bandwidth = Bandwidth()
    
    var localAddress: String? = nil // local IP
    var remoteAddress: NetworkAddress = NetworkAddress() // remote IP
    
    var interface: NetworkInterface? = nil
    var connectionType: NetworkType? = nil
    var status: Bool = false
    
    var wifiDetails: NetworkWifi = NetworkWifi()
    
    mutating func reset() {
        self.bandwidth = Bandwidth()
        
        self.localAddress = nil
        self.remoteAddress = NetworkAddress()
        
        self.interface = nil
        self.connectionType = nil
        
        self.wifiDetails.reset()
    }
    
    public var widgetValue: Double = 0
}

//
//  File.swift
//  
//
//  Created by Ibrahim on 4/18/24.
//

import Foundation
import CoreWLAN

struct ipResponse: Decodable {
    var ip: String
    var country: String
    var cc: String
}

// swiftlint:disable control_statement
extension CWPHYMode: CustomStringConvertible {
    public var description: String {
        switch(self) {
        case .mode11a:  return "802.11a"
        case .mode11ac: return "802.11ac"
        case .mode11b:  return "802.11b"
        case .mode11g:  return "802.11g"
        case .mode11n:  return "802.11n"
        case .mode11ax: return "802.11ax"
        case .modeNone: return "none"
        @unknown default: return "unknown"
        }
    }
}

extension CWInterfaceMode: CustomStringConvertible {
    public var description: String {
        switch(self) {
        case .hostAP:       return "AP"
        case .IBSS:         return "Adhoc"
        case .station:      return "Station"
        case .none:         return "none"
        @unknown default:   return "unknown"
        }
    }
}

extension CWSecurity: CustomStringConvertible {
    public var description: String {
        switch(self) {
        case .none:               return "none"
        case .WEP:                return "WEP"
        case .wpaPersonal:        return "WPA Personal"
        case .wpaPersonalMixed:   return "WPA Personal Mixed"
        case .wpa2Personal:       return "WPA2 Personal"
        case .personal:           return "Personal"
        case .dynamicWEP:         return "Dynamic WEP"
        case .wpaEnterprise:      return "WPA Enterprise"
        case .wpaEnterpriseMixed: return "WPA Enterprise Mixed"
        case .wpa2Enterprise:     return "WPA2 Enterprise"
        case .enterprise:         return "Enterprise"
        case .unknown:            return "unknown"
        case .wpa3Personal:       return "WPA3 Personal"
        case .wpa3Enterprise:     return "WPA3 Enterprise"
        case .wpa3Transition:     return "WPA3 Transition"
        default:                  return "unknown"
        }
    }
}

extension CWChannelBand: CustomStringConvertible {
    public var description: String {
        switch(self) {
        case .band2GHz:     return "2 GHz"
        case .band5GHz:     return "5 GHz"
        case .band6GHz:     return "6 GHz"
        case .bandUnknown:  return "unknown"
        @unknown default:   return "unknown"
        }
    }
}

extension CWChannelWidth: CustomStringConvertible {
    public var description: String {
        switch(self) {
        case .width20MHz:   return "20 MHz"
        case .width40MHz:   return "40 MHz"
        case .width80MHz:   return "80 MHz"
        case .width160MHz:  return "160 MHz"
        case .widthUnknown: return "unknown"
        @unknown default:   return "unknown"
        }
    }
}
// swiftlint:enable control_statement

extension CWChannel {
    override public var description: String {
        return "\(channelNumber) (\(channelBand), \(channelWidth))"
    }
}

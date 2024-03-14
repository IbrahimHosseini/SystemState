//
//  DeviceType.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation

public enum DeviceType: String {
    case unknown
    case macMini
    case macPro
    case iMac
    case iMacPro
    case macbook
    case macbookAir
    case macbookPro
    case macStudio
    
    public static var all: [DeviceType] {
        return [.macMini, .macPro, .iMac, .iMacPro, .macbook, .macbookAir, .macbookPro, .macStudio]
    }
}

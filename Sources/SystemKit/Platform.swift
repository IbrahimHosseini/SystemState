//
//  Platform.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation

public enum Platform: String, Codable {
    case intel
    
    case m1
    case m1Pro
    case m1Max
    case m1Ultra
    
    case m2
    case m2Pro
    case m2Max
    case m2Ultra
    
    case m3
    case m3Pro
    case m3Max
    case m3Ultra
    
    public static var apple: [Platform] {
        return [
            .m1, .m1Pro, .m1Max, .m1Ultra,
            .m2, .m2Pro, .m2Max, .m2Ultra,
            .m3, .m3Pro, .m3Max, .m3Ultra
        ]
    }
    
    public static var all: [Platform] {
        return apple + [.intel]
    }
}

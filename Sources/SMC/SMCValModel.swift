//
//  SMCValModel.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation

public struct SMCValModel {
    var key: String
    var dataSize: UInt32 = 0
    var dataType: String = ""
    var bytes: [UInt8] = Array(repeating: 0, count: 32)
    
    init(_ key: String) {
        self.key = key
    }
}

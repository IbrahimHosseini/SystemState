//
//  Float+extension.swift
//
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation

public extension Float {
    init?(_ bytes: [UInt8]) {
        self = bytes.withUnsafeBytes {
            return $0.load(fromByteOffset: 0, as: Self.self)
        }
    }
    
    var bytes: [UInt8] {
        withUnsafeBytes(of: self, Array.init)
    }
}

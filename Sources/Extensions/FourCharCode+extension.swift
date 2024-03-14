//
//  FourCharCode+extension.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation

public extension FourCharCode {
    init(fromString str: String) {
        precondition(str.count == 4)
        
        self = str.utf8.reduce(0) { sum, character in
            return sum << 8 | UInt32(character)
        }
    }
    
    func toString() -> String {
        return String(describing: UnicodeScalar(self >> 24 & 0xff)!) +
               String(describing: UnicodeScalar(self >> 16 & 0xff)!) +
               String(describing: UnicodeScalar(self >> 8  & 0xff)!) +
               String(describing: UnicodeScalar(self       & 0xff)!)
    }
}

//
//  OperatingSystemVersion+extension.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation

public extension OperatingSystemVersion {
    func getFullVersion(separator: String = ".") -> String {
        return "\(majorVersion)\(separator)\(minorVersion)\(separator)\(patchVersion)"
    }
}

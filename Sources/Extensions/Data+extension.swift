//
//  Data+extension.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation

public extension Data {
    var socketAddress: sockaddr {
        return withUnsafeBytes { $0.load(as: sockaddr.self) }
    }
    var socketAddressInternet: sockaddr_in {
        return withUnsafeBytes { $0.load(as: sockaddr_in.self) }
    }
}

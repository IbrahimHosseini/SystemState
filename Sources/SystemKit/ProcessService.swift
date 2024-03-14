//
//  ProcessService.swift
//  
//
//  Created by Ibrahim on 3/11/24.
//

import Cocoa

public protocol ProcessService {
    var pid: Int { get }
    var name: String { get }
}


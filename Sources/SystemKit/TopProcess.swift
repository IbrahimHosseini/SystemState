//
//  TopProcess.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation

public struct TopProcess: Codable, ProcessService {
    public var pid: Int
    public var name: String
    public var usage: Double
    
    public init(pid: Int, name: String, usage: Double) {
        self.pid = pid
        self.name = name
        self.usage = usage
    }
}

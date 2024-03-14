//
//  File.swift
//  
//
//  Created by Ibrahim on 3/11/24.
//

import Cocoa

public protocol Process_p {
    var pid: Int { get }
    var name: String { get }
}

public typealias ProcessHeader = (title: String, color: NSColor?)


//
//  ModuleService.swift
//
//
//  Created by Ibrahim on 3/11/24.
//


import Foundation

public protocol ModuleService {
    var available: Bool { get }
        
    func mount()
    func unmount()
    
    func terminate()
}

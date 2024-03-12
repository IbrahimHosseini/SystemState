//
//  File.swift
//  
//
//  Created by Ibrahim on 3/11/24.
//

import Foundation

@objc public protocol HelperProtocol {
    func version(completion: @escaping (String) -> Void)
    func setSMCPath(_ path: String)
    
    func setFanMode(id: Int, mode: Int, completion: @escaping (String?) -> Void)
    func setFanSpeed(id: Int, value: Int, completion: @escaping (String?) -> Void)
    func powermetrics(_ samplers: [String], completion: @escaping (String?) -> Void)
    
    func uninstall()
}

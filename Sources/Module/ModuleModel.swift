//
//  ModuleModel.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation

public struct ModuleModel {
    public var name: String = ""
    
    public var defaultState: Bool = false
    
    internal var widgetsConfig: NSDictionary = NSDictionary()
    
    init(in path: String) {
        guard let dict: NSDictionary = NSDictionary(contentsOfFile: path) else { return }
        
        if let name = dict["Name"] as? String {
            self.name = name
        }
        
        if let state = dict["State"] as? Bool {
            self.defaultState = state
        }
    }
}

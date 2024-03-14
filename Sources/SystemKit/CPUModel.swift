//
//  CPUModel.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation

public struct CPUModel {
    public var name: String? = nil
    public var physicalCores: Int8? = nil
    public var logicalCores: Int8? = nil
    public var eCores: Int32? = nil
    public var pCores: Int32? = nil
    public var cores: [CoreModel]? = nil
}

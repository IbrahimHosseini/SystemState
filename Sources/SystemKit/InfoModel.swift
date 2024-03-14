//
//  InfoModel.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation

public struct InfoModel {
    public var cpu: CPUModel? = nil
    public var ram: MemoryModel? = nil
    public var gpu: [GPUModel]? = nil
    public var disk: StorageModel? = nil
}

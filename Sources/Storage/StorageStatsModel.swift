//
//  StorageStatsModel.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation

internal struct StorageStatsModel: Codable {
    var read: Int64 = 0
    var write: Int64 = 0
    
    var readBytes: Int64 = 0
    var writeBytes: Int64 = 0
}

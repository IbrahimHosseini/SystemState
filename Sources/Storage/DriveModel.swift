//
//  DriveModel.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation
import SystemKit

public struct DriveModel: Codable {
    var parent: io_object_t = 0
    
    var mediaName: String = ""
    var BSDName: String = ""
    
    var root: Bool = false
    var removable: Bool = false
    
    var model: String = ""
    var path: URL?
    var connectionType: String = ""
    var fileSystem: String = ""
    
    var size: Int64 = 1
    var free: Int64 = 0
    
    var activity: StorageStatsModel = StorageStatsModel()
    var smart: SmartModel? = nil
    
    var percentage: Double {
        let total = self.size
        let free = self.free
        var usedSpace = total - free
        if usedSpace < 0 {
            usedSpace = 0
        }
        return Double(usedSpace) / Double(total)
    }
}

extension Int64 {
    var readableStorage: String {
        DiskSize(self).getReadableStorage()
    }
}


public struct StorageModel {
    let total: Int64
    let free: Int64
    let used: Int64
}

//
//  StorageProcess.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import SystemKit
import AppKit
import Common

public struct StorageProcess: ProcessService, Codable {
    public var base: StorageSizeBase {
        StorageSizeBase(rawValue: Store.shared.string(key: "\(ModuleType.storage.rawValue)_base", defaultValue: "byte")) ?? .byte
    }
    
    public var pid: Int
    public var name: String
    
    var read: Int
    var write: Int
    
    init(pid: Int, name: String, read: Int, write: Int) {
        self.pid = pid
        self.name = name
        self.read = read
        self.write = write
        
        if let app = NSRunningApplication(processIdentifier: pid_t(pid)) {
            if let name = app.localizedName {
                self.name = name
            }
        }
    }
}

//
//  StorageProcess.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

#if os(macOS)
import AppKit
#endif
import SystemKit
import Common
import Constants

public struct StorageProcess: ProcessService, Codable {
    
    public var base: StorageSizeBase {
        StorageSizeBase(rawValue: Store.shared.string(key: "\(ModuleType.storage.rawValue)_base", defaultValue: "byte")) ?? .byte
    }
    
    public var pid: Int
    public var name: String
    public var icon: NSImage {
        if let app = NSRunningApplication(processIdentifier: pid_t(self.pid)) {
            return app.icon ?? Constants.defaultProcessIcon
        }
        return Constants.defaultProcessIcon
    }
    
    public var read: Int
    public var write: Int
    
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

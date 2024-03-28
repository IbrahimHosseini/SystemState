//
//  TopProcess.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

#if os(macOS)
import AppKit
#endif
import Constants

public struct TopProcess: Codable, ProcessService {
    public var pid: Int
    public var name: String
    public var usage: Double
    public var icon: NSImage {
        get {
            if let app = NSRunningApplication(processIdentifier: pid_t(self.pid)), let icon = app.icon {
                return icon
            }
            return Constants.defaultProcessIcon
        }
    }
    
    public init(pid: Int, name: String, usage: Double) {
        self.pid = pid
        self.name = name
        self.usage = usage
    }
}

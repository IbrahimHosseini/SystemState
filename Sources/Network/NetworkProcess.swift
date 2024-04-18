//
//  NetworkProcess.swift
//
//
//  Created by Ibrahim on 4/18/24.
//

import AppKit
import SystemKit
import Constants

public struct NetworkProcess: Codable, ProcessService {
    public var pid: Int
    public var name: String
    public var time: Date
    public var download: Int
    public var upload: Int
    public var icon: NSImage {
        get {
            if let app = NSRunningApplication(processIdentifier: pid_t(self.pid)), let icon = app.icon {
                return icon
            }
            return Constants.defaultProcessIcon
        }
    }
    
    public init(
        pid: Int = 0,
        name: String = "",
        time: Date = Date(),
        download: Int = 0,
        upload: Int = 0
    ) {
        self.pid = pid
        self.name = name
        self.time = time
        self.download = download
        self.upload = upload
    }
}

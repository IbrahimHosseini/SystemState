//
//  DiskSize.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation

public struct DiskSize {
    public let value: Int64
    
    public init(_ size: Int64) {
        self.value = size
    }
    
    public var kilobytes: Double {
        return Double(value) / 1_000
    }
    public var megabytes: Double {
        return kilobytes / 1_000
    }
    public var gigabytes: Double {
        return megabytes / 1_000
    }
    public var terabytes: Double {
        return gigabytes / 1_000
    }
    
    public func getReadableMemory() -> String {
        switch value {
        case 0..<1_000:
            return "0 KB"
        case 1_000..<(1_000 * 1_000):
            return String(format: "%.0f KB", kilobytes)
        case 1_000..<(1_000 * 1_000 * 1_000):
            return String(format: "%.0f MB", megabytes)
        case 1_000..<(1_000 * 1_000 * 1_000 * 1_000):
            return String(format: "%.1f GB", gigabytes)
        case (1_000 * 1_000 * 1_000 * 1_000)...Int64.max:
            return String(format: "%.1f TB", terabytes)
        default:
            return String(format: "%.0f KB", kilobytes)
        }
    }
}

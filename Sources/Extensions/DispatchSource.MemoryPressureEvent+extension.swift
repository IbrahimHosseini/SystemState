//
//  DispatchSource.MemoryPressureEvent+extension.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

#if os(macOS)
import AppKit
#endif

public extension DispatchSource.MemoryPressureEvent {
    func pressureColor() -> NSColor {
        switch self {
        case .normal:
            return NSColor.systemGreen
        case .warning:
            return NSColor.systemYellow
        case .critical:
            return NSColor.systemRed
        default:
            if #available(macOS 10.14, *) {
                return .controlAccentColor
            } else {
                return .black
            }
        }
    }
}

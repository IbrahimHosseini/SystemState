//
//  ModuleType.swift
//
//
//  Created by Ibrahim on 3/11/24.
//

#if os(macOS)
import AppKit
#endif

public enum ModuleType: Int {
    case CPU
    case Memory
    case GPU
    case storage
    case sensors
    case network
    case battery
    case bluetooth
    case clock
    
    public var rawValue: String {
        switch self {
        case .CPU: return "CPU"
        case .Memory: return "Memory"
        case .GPU: return "GPU"
        case .storage: return "Disk"
        case .sensors: return "Sensors"
        case .network: return "Network"
        case .battery: return "Battery"
        case .bluetooth: return "Bluetooth"
        case .clock: return "Clock"
        }
    }
}


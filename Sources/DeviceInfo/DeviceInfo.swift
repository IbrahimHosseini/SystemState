//
//  File.swift
//  
//
//  Created by Ibrahim on 3/17/24.
//

import Foundation
import SystemKit
import Extensions

/// Device hardware informations
public enum DeviceInfo {
    
    /// mac os name
    public static  let osName = SystemKit.shared.device.os?.name ?? "Unknown"
    
    /// mac os version
    public static let osFullVersion = SystemKit.shared.device.os?.version.getFullVersion() ?? "Unknown"
    
    /// CPU Model
    public static let cpuName = SystemKit.shared.device.info.cpu?.name ?? "Unknown"
    
    public static let memory: String = {
        let sizeFormatter = ByteCountFormatter()
        sizeFormatter.allowedUnits = [.useGB]
        sizeFormatter.countStyle = .memory
        
        var value = ""
        if let dimms = SystemKit.shared.device.info.ram?.dimms {
            for i in 0..<dimms.count {
                let dimm = dimms[i]
                var row = ""
                
                if let size = dimm.size {
                    row += size
                }
                
                if let speed = dimm.speed {
                    if !row.isEmpty && row.last != " " {
                        row += " "
                    }
                    row += speed
                }
                
                if let type = dimm.type {
                    if !row.isEmpty && row.last != " " {
                        row += " "
                    }
                    row += type
                }
                
                if dimm.bank != nil || dimm.channel != nil {
                    if !row.isEmpty && row.last != " " {
                        row += " "
                    }
                    
                    var mini = "("
                    if let bank = dimm.bank {
                        mini += "slot \(bank)"
                    }
                    if let ch = dimm.channel {
                        mini += "\(mini == "(" ? "" : "/")ch \(ch)"
                    }
                    row += "\(mini))"
                }
                
                value += "\(row)\(i == dimms.count-1 ? "" : "\n")"
            }
        } else {
            value = localizedString("Unknown")
        }
        
        return value
    }()
    
    public static let gpu: String = {
        var value = ""
        if let gpus = SystemKit.shared.device.info.gpu {
            for i in 0..<gpus.count {
                var row = gpus[i].name != nil ? gpus[i].name! : localizedString("Unknown")
                
                if gpus[i].vram != nil || gpus[i].cores != nil {
                    row += " ("
                    if let cores = gpus[i].cores {
                        row += localizedString("Number of cores", "\(cores)")
                    }
                    if let size = gpus[i].vram {
                        if gpus[i].cores != nil {
                            row += ", \(size)"
                        } else {
                            row += "\(size)"
                        }
                    }
                    row += ")"
                }
                
                value += "\(row)\(i == gpus.count-1 ? "" : "\n")"
            }
        } else {
            value = localizedString("Unknown")
        }
        
        return value
    }()
    
    /// Storage Model
    public static let storageModel = SystemKit.shared.device.info.disk?.model ?? SystemKit.shared.device.info.disk?.name ?? "Unknown"
    
    /// Storage size
    public static let storageSize = DiskSize(SystemKit.shared.device.info.disk?.size ?? 0).getReadableMemory()
    
    /// CPU Uptime
    public static let uptime: Date = SystemKit.shared.device.bootDate ?? Date()
    
    /// CPU uptime with readable format
    public static let uptimeDayHourMinuteFormat: String = uptime.dayHourMinuteFormat
    
    /// Device serial number
    public static let serialNumber = SystemKit.shared.device.serialNumber ?? "Unknown"
     
}


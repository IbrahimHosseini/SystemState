//
//  Double+extension.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import AppKit
import Common

public extension Double {
    func roundTo(decimalPlaces: Int) -> String {
        return NSString(format: "%.\(decimalPlaces)f" as NSString, self) as String
    }
    
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    func usageColor(zones: colorZones = (0.6, 0.8), reversed: Bool = false) -> NSColor {
        let firstColor: NSColor = NSColor.systemBlue
        let secondColor: NSColor = NSColor.orange
        let thirdColor: NSColor = NSColor.red
        
        if reversed {
            switch self {
            case 0...zones.orange:
                return thirdColor
            case zones.orange...zones.red:
                return secondColor
            default:
                return firstColor
            }
        } else {
            switch self {
            case 0...zones.orange:
                return firstColor
            case zones.orange...zones.red:
                return secondColor
            default:
                return thirdColor
            }
        }
    }
    
    func percentageColor(color: Bool) -> NSColor {
        if !color {
            return NSColor.textColor
        }
        
        switch self {
        case 0.6...0.8:
            return NSColor.systemOrange
        case 0.8...1:
            return NSColor.systemRed
        default:
            return NSColor.systemGreen
        }
    }
    
    func batteryColor(color: Bool = false, lowPowerMode: Bool? = nil) -> NSColor {
        if let mode = lowPowerMode, mode {
            return NSColor.systemOrange
        }
        
        switch self {
        case 0.2...0.4:
            if !color {
                return NSColor.textColor
            }
            return NSColor.systemOrange
        case 0.4...1:
            if self == 1 {
                return NSColor.textColor
            }
            if !color {
                return NSColor.textColor
            }
            return NSColor.systemGreen
        default:
            return NSColor.systemRed
        }
    }
    
    func secondsToHoursMinutesSeconds() -> (Int, Int) {
        let mins = (self.truncatingRemainder(dividingBy: 3600)) / 60
        return (Int(self / 3600), Int(mins))
    }
    
    func printSecondsToHoursMinutesSeconds(short: Bool = false) -> String {
        let (h, m) = self.secondsToHoursMinutesSeconds()
        
        if self == 0 || h < 0 || m < 0 {
            return "n/a"
        }
        
        let minutes = m > 9 ? "\(m)" : "0\(m)"
        
        if short {
            return "\(h):\(minutes)"
        }
        
        if h == 0 {
            return "\(minutes)min"
        } else if m == 0 {
            return "\(h)h"
        }
        
        return "\(h)h \(minutes)min"
    }
}

internal extension Double {
    var showAsBatteryPercent: String {
        "\(Int(abs(self) * 100))%"
    }
}

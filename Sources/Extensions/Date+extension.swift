//
//  Date+extension.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation

public extension Date {
    func convertToTimeZone(_ timeZone: TimeZone) -> Date {
        return addingTimeInterval(TimeInterval(timeZone.secondsFromGMT(for: self) - TimeZone.current.secondsFromGMT(for: self)))
    }
    
    func currentTimeSeconds() -> Int {
        return Int(self.timeIntervalSince1970)
    }
}

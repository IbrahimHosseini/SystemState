//
//  Timezone+extension.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation

public extension TimeZone {
    init(fromUTC: String) {
        if fromUTC == "local" {
            self = TimeZone.current
            return
        }
        
        let arr = fromUTC.split(separator: ":")
        guard !arr.isEmpty else {
            self = TimeZone.current
            return
        }
        
        var secondsFromGMT = 0
        if arr.indices.contains(0), let h = Int(arr[0]) {
            secondsFromGMT += h*3600
        }
        if arr.indices.contains(1), let m = Int(arr[1]) {
            if secondsFromGMT < 0 {
                secondsFromGMT -= m*60
            } else {
                secondsFromGMT += m*60
            }
        }
        
        if let tz = TimeZone(secondsFromGMT: secondsFromGMT) {
            self = tz
        } else {
            self = TimeZone.current
        }
    }
}


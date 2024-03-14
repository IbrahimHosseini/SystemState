//
//  LimitReader.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import SystemKit
import AppKit

public class LimitReader: Reader<CPULimitModel> {
    private var limits: CPULimitModel = CPULimitModel()
    
    public override func read() {
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["-g", "therm"]
        
        let outputPipe = Pipe()
        defer {
            outputPipe.fileHandleForReading.closeFile()
        }
        task.standardOutput = outputPipe
        
        do {
            try task.run()
        } catch let err {
            error("error read pmset: \(err.localizedDescription)", log: self.log)
            return
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        var lines = String(decoding: outputData, as: UTF8.self).split(separator: "\n")
        if lines.isEmpty {
            return
        }
        lines.removeFirst(3)
        
        lines.forEach { (line: Substring) in
            guard let value = Int(line.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) else {
                return
            }
            if line.contains("Scheduler") {
                self.limits.scheduler = value
            } else if line.contains("CPUs") {
                self.limits.cpus = value
            } else if line.contains("Speed") {
                self.limits.speed = value
            }
        }
        
        self.callback(self.limits)
    }
}

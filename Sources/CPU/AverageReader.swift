//
//  AverageReader.swift
//
//
//  Created by Ibrahim on 3/14/24.
//

import SystemKit
import AppKit

internal class AverageReader: Reader<[Double]> {
    private let title: String = "CPU"
    
    public override func setup() {
        self.setInterval(60)
    }
    
    public override func read() {
        let task = Process()
        task.launchPath = "/usr/bin/uptime"
        
        let outputPipe = Pipe()
        defer {
            outputPipe.fileHandleForReading.closeFile()
        }
        task.standardOutput = outputPipe
        
        do {
            try task.run()
        } catch let err {
            error("error read uptime: \(err.localizedDescription)", log: self.log)
            return
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let line = String(decoding: outputData, as: UTF8.self).split(separator: "\n").first else {
            return
        }
        
        let str = line.trimmingCharacters(in: .whitespaces)
        let strFind = str.findAndCrop(pattern: "(\\d+(.|,)\\d+ *){3}$")
        let strArr = strFind.cropped.split(separator: " ")
        guard strArr.count == 3 else {
            return
        }
        
        var list: [Double] = []
        strArr.forEach { (n: Substring) in
            let value = Double(n.replacingOccurrences(of: ",", with: ".")) ?? 0
            list.append(value)
        }
        
        self.callback(list)
    }
}

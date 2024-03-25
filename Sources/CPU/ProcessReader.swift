//
//  ProcessReader.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import SystemKit
import AppKit

internal class ProcessReader: Reader<[TopProcess]> {
    private let title: String = "CPU"
    
    private var numberOfProcesses: Int {
        get {
            return Store.shared.int(key: "\(self.title)_processes", defaultValue: 8)
        }
    }
    
    public override func setup() {
        self.popup = true
        self.setInterval(Store.shared.int(key: "\(self.title)_updateTopInterval", defaultValue: 1))
    }
    
    public override func read() {
        if self.numberOfProcesses == 0 {
            return
        }
        
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-Aceo pid,pcpu,comm", "-r"]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        defer {
            outputPipe.fileHandleForReading.closeFile()
            errorPipe.fileHandleForReading.closeFile()
        }
        
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        do {
            try task.run()
        } catch let err {
            error("error read ps: \(err.localizedDescription)", log: self.log)
            return
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)
        _ = String(decoding: errorData, as: UTF8.self)
        
        if output.isEmpty {
            return
        }
        
        var index = 0
        var processes: [TopProcess] = []
        output.enumerateLines { (line, stop) -> Void in
            if index != 0 {
                let str = line.trimmingCharacters(in: .whitespaces)
                let pidFind = str.findAndCrop(pattern: "^\\d+")
                let usageFind = pidFind.remain.findAndCrop(pattern: "^[0-9,.]+ ")
                let command = usageFind.remain.trimmingCharacters(in: .whitespaces)
                let pid = Int(pidFind.cropped) ?? 0
                let usage = Double(usageFind.cropped.replacingOccurrences(of: ",", with: ".")) ?? 0
                
                var name: String = command
                if let app = NSRunningApplication(processIdentifier: pid_t(pid)), let n = app.localizedName {
                    name = n
                }
                
                processes.append(TopProcess(pid: pid, name: name, usage: usage))
            }
            
            if index == self.numberOfProcesses { stop = true }
            index += 1
        }
        
        self.callback(processes)
    }
}

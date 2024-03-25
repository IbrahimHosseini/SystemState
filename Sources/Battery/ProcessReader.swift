//
//  ProcessReader.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import SystemKit
import AppKit

internal class ProcessReader: Reader<[TopProcess]> {
    private var numberOfProcesses: Int {
        get {
            return Store.shared.int(key: "Battery_processes", defaultValue: 8)
        }
    }
    
    public override func setup() {
        self.popup = true
    }
    
    public override func read() {
        if self.numberOfProcesses == 0 {
            return
        }
        
        let task = Process()
        task.launchPath = "/usr/bin/top"
        task.arguments = ["-o", "power", "-l", "2", "-n", "\(self.numberOfProcesses)", "-stats", "pid,command,power"]
        
        let outputPipe = Pipe()
        defer {
            outputPipe.fileHandleForReading.closeFile()
        }
        task.standardOutput = outputPipe
        
        do {
            try task.run()
        } catch let err {
            error("error read ps: \(err.localizedDescription)", log: self.log)
            return
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        if outputData.isEmpty {
            return
        }
        
        let output = String(decoding: outputData.advanced(by: outputData.count/2), as: UTF8.self)
        if output.isEmpty {
            return
        }
        
        var processes: [TopProcess] = []
        output.enumerateLines { (line, _) -> Void in
            if line.matches("^\\d+ *[^(\\d)]*\\d+\\.*\\d* *$") {
                let str = line.trimmingCharacters(in: .whitespaces)
                let pidFind = str.findAndCrop(pattern: "^\\d+")
                let usageFind = pidFind.remain.findAndCrop(pattern: " +[0-9]+.*[0-9]*$")
                let command = usageFind.remain.trimmingCharacters(in: .whitespaces)
                let pid = Int(pidFind.cropped) ?? 0
                guard let usage = Double(usageFind.cropped.filter("01234567890.".contains)) else {
                    return
                }
                
                var name: String = command
                if let app = NSRunningApplication(processIdentifier: pid_t(pid)), let n = app.localizedName {
                    name = n
                }
                
                processes.append(TopProcess(pid: pid, name: name, usage: usage))
            }
        }
        
        self.callback(processes.suffix(self.numberOfProcesses).sorted(by: { $0.usage > $1.usage }))
    }
}

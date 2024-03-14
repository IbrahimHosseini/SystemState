//
//  ProcessReader.swift
//
//
//  Created by Ibrahim on 3/14/24.
//

import SystemKit
import AppKit

public class ProcessReader: Reader<[TopProcess]> {
    private let title: String = "Memory"
    
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
        task.launchPath = "/usr/bin/top"
        task.arguments = ["-l", "1", "-o", "mem", "-n", "\(self.numberOfProcesses)", "-stats", "pid,command,mem"]
        
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
            error("top(): \(err.localizedDescription)", log: self.log)
            return
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)
        _ = String(decoding: errorData, as: UTF8.self)
        
        if output.isEmpty {
            return
        }
        
        var processes: [TopProcess] = []
        output.enumerateLines { (line, _) -> Void in
            if line.matches("^\\d+\\** +.* +\\d+[A-Z]*\\+?\\-? *$") {
                processes.append(ProcessReader.parseProcess(line))
            }
        }
        
        self.callback(processes)
    }
    
    static public func parseProcess(_ raw: String) -> TopProcess {
        var str = raw.trimmingCharacters(in: .whitespaces)
        let pidString = str.find(pattern: "^\\d+")
        
        if let range = str.range(of: pidString) {
            str = str.replacingCharacters(in: range, with: "")
        }
        
        var arr = str.split(separator: " ")
        if arr.first == "*" {
            arr.removeFirst()
        }
        
        var usageString = str.suffix(6)
        if let lastElement = arr.last {
            usageString = lastElement
            arr.removeLast()
        }
        
        var command = arr.joined(separator: " ")
            .replacingOccurrences(of: pidString, with: "")
            .trimmingCharacters(in: .whitespaces)
        
        if let regex = try? NSRegularExpression(pattern: " (\\+|\\-)*$", options: .caseInsensitive) {
            command = regex.stringByReplacingMatches(in: command, options: [], range: NSRange(location: 0, length: command.count), withTemplate: "")
        }
        
        let pid = Int(pidString.filter("01234567890.".contains)) ?? 0
        var usage = Double(usageString.filter("01234567890.".contains)) ?? 0
        if usageString.last == "G" {
            usage *= 1024 // apply gigabyte multiplier
        } else if usageString.last == "K" {
            usage /= 1024 // apply kilobyte divider
        }
        
        var name: String = command
        if let app = NSRunningApplication(processIdentifier: pid_t(pid)), let n = app.localizedName {
            name = n
        }
        
        return TopProcess(pid: pid, name: name, usage: usage * Double(1024 * 1024))
    }
}

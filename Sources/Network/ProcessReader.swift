//
//  ProcessReader.swift
//
//
//  Created by Ibrahim on 4/18/24.
//

import SystemKit
import AppKit

public class ProcessReader: Reader<[NetworkProcess]> {
    private let title: String = "Network"
    private var previous: [NetworkProcess] = []
    
    private var numberOfProcesses: Int {
        get {
            return Store.shared.int(key: "\(self.title)_processes", defaultValue: 8)
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
        task.launchPath = "/usr/bin/nettop"
        task.arguments = ["-P", "-L", "1", "-n", "-k", "time,interface,state,rx_dupe,rx_ooo,re-tx,rtt_avg,rcvsize,tx_win,tc_class,tc_mgt,cc_algo,P,C,R,W,arch"]
        
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
        } catch let error {
            print(error)
            return
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)
        _ = String(decoding: errorData, as: UTF8.self)
        
        if output.isEmpty {
            return
        }
        
        var list: [NetworkProcess] = []
        var firstLine = false
        output.enumerateLines { (line, _) -> Void in
            if !firstLine {
                firstLine = true
                return
            }
            
            let parsedLine = line.split(separator: ",")
            guard parsedLine.count >= 3 else {
                return
            }
            
            var process = NetworkProcess()
            process.time = Date()
            
            let nameArray = parsedLine[0].split(separator: ".")
            if let pid = nameArray.last {
                process.pid = Int(pid) ?? 0
            }
            if let app = NSRunningApplication(processIdentifier: pid_t(process.pid) ) {
                process.name = app.localizedName ?? nameArray.dropLast().joined(separator: ".")
            } else {
                process.name = nameArray.dropLast().joined(separator: ".")
            }
            
            if process.name == "" {
                process.name = "\(process.pid)"
            }
            
            if let download = Int(parsedLine[1]) {
                process.download = download
            }
            if let upload = Int(parsedLine[2]) {
                process.upload = upload
            }
            
            list.append(process)
        }
        
        var processes: [NetworkProcess] = []
        if self.previous.isEmpty {
            self.previous = list
            processes = list
        } else {
            self.previous.forEach { (pp: NetworkProcess) in
                if let i = list.firstIndex(where: { $0.pid == pp.pid }) {
                    let p = list[i]
                    
                    var download = p.download - pp.download
                    var upload = p.upload - pp.upload
                    let time = download == 0 && upload == 0 ? pp.time : Date()
                    list[i].time = time
                    
                    if download < 0 {
                        download = 0
                    }
                    if upload < 0 {
                        upload = 0
                    }
                    
                    processes.append(
                        NetworkProcess(
                            pid: p.pid,
                            name: p.name,
                            time: time,
                            download: download,
                            upload: upload
                        )
                    )
                }
            }
            self.previous = list
        }
        
        processes.sort {
            let firstMax = max($0.download, $0.upload)
            let secondMax = max($1.download, $1.upload)
            let firstMin = min($0.download, $0.upload)
            let secondMin = min($1.download, $1.upload)
            
            if firstMax == secondMax && firstMin == secondMin { // download and upload values are the same, sort by time
                return $0.time < $1.time
            } else if firstMax == secondMax && firstMin != secondMin { // max values are the same, min not. Sort by min values
                return firstMin < secondMin
            }
            return firstMax < secondMax // max values are not the same, sort by max value
        }
        
        self.callback(processes.suffix(self.numberOfProcesses).reversed())
    }

}

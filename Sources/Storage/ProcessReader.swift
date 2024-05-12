//
//  ProcessReader.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation
import SystemKit

internal class ProcessReader: Reader<[StorageProcess]> {
    private let queue = DispatchQueue(label: "eu.exelban.Disk.processReader")
    
    private var _list: [Int32: IOModel] = [:]
    private var list: [Int32: IOModel] {
        get {
            self.queue.sync { self._list }
        }
        set {
            self.queue.sync { self._list = newValue }
        }
    }
    
    private var numberOfProcesses: Int {
        Store.shared.int(key: "\(ModuleType.storage.rawValue)_processes", defaultValue: 10)
    }
    
    public override func setup() {
        self.popup = true
        self.setInterval(1)
    }
    
    public override func read() {
        guard self.numberOfProcesses != 0, let output = runProcess(path: "/bin/ps", args: ["-Aceo pid,args", "-r"]) else { return }
        
        var processes: [StorageProcess] = []
        output.enumerateLines { (line, _) -> Void in
            let str = line.trimmingCharacters(in: .whitespaces)
            let pidFind = str.findAndCrop(pattern: "^\\d+")
            guard let pid = Int32(pidFind.cropped) else { return }
            let name = pidFind.remain.findAndCrop(pattern: "^[^ ]+").cropped
            
            var usage = rusage_info_current()
            let result = withUnsafeMutablePointer(to: &usage) {
                $0.withMemoryRebound(to: (rusage_info_t?.self), capacity: 1) {
                    proc_pid_rusage(pid, RUSAGE_INFO_CURRENT, $0)
                }
            }
            guard result != -1 else { return }
            
            let bytesRead = Int(usage.ri_diskio_bytesread)
            let bytesWritten = Int(usage.ri_diskio_byteswritten)
            
            if self.list[pid] == nil {
                self.list[pid] = IOModel(read: bytesRead, write: bytesWritten)
            }
            
            if let v = self.list[pid] {
                let read = bytesRead - v.read
                let write = bytesWritten - v.write
                if read != 0 || write != 0 {
                    processes.append(StorageProcess(pid: Int(pid), name: name, read: read, write: write))
                }
            }
            
            self.list[pid]?.read = bytesRead
            self.list[pid]?.write = bytesWritten
        }
        
        processes.sort {
            let firstMax = max($0.read, $0.write)
            let secondMax = max($1.read, $1.write)
            let firstMin = min($0.read, $0.write)
            let secondMin = min($1.read, $1.write)
            
            if firstMax == secondMax && firstMin != secondMin { // max values are the same, min not. Sort by min values
                return firstMin < secondMin
            }
            return firstMax < secondMax // max values are not the same, sort by max value
        }
        
        self.callback(processes.suffix(self.numberOfProcesses).reversed())
    }
}

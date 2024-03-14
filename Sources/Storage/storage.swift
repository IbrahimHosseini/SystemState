//
//  storage.swift
//
//
//  Created by Ibrahim on 3/14/24.
//

import Cocoa
import Kit

public struct Disk_process: Process_p, Codable {
    public var base: DataSizeBase {
        DataSizeBase(rawValue: Store.shared.string(key: "\(ModuleType.disk.rawValue)_base", defaultValue: "byte")) ?? .byte
    }
    
    public var pid: Int
    public var name: String
    
    var read: Int
    var write: Int
    
    init(pid: Int, name: String, read: Int, write: Int) {
        self.pid = pid
        self.name = name
        self.read = read
        self.write = write
        
        if let app = NSRunningApplication(processIdentifier: pid_t(pid)) {
            if let name = app.localizedName {
                self.name = name
            }
        }
    }
}

public class Disk: Module {
    
    private var capacityReader: CapacityReader?
    private var activityReader: ActivityReader?
    private var processReader: ProcessReader?
    
    private var selectedDisk: String = ""
    
    public var storageInfo = ""
    
    public override init() {
        super.init()
        guard self.available else { return }
        
        self.capacityReader = CapacityReader(.disk) { [weak self] value in
            if let value {
                self?.capacityCallback(value)
            }
        }
        self.activityReader = ActivityReader(.disk) { [weak self] value in
            if let value {
                self?.activityCallback(value)
            }
        }
        self.processReader = ProcessReader(.disk) { [weak self] value in
            if let list = value {
                self?.processCallback(list)
            }
        }
        
        self.selectedDisk = Store.shared.string(key: "\(ModuleType.disk.rawValue)_disk", defaultValue: self.selectedDisk)
        
        self.capacityReader?.read()
        
        self.capacityReader?.read()
        
        self.capacityReader?.setInterval(1)
        
        DispatchQueue.global(qos: .background).async {
            self.processReader?.read()
        }
        
        self.setReaders([self.capacityReader, self.activityReader, self.processReader])
    }
    
    private func capacityCallback(_ value: Disks) {
        
        guard let d = value.first(where: { $0.mediaName == self.selectedDisk }) ?? value.first(where: { $0.root }) else {
            return
        }
        
        let free = DiskSize(d.free).getReadableMemory()
        let total = DiskSize(d.size).getReadableMemory()
        let used = DiskSize(d.size - d.free).getReadableMemory()
        
        storageInfo = "Total: \(total), Free: \(free), used: \(used)"
        
        print("""
            ===================STORAGE====================
            \(storageInfo)
            """)
    }
    
}

extension Disk {
    internal func processCallback(_ list: [Disk_process]) {
        
        let list = list.map{ $0 }
        
        for i in 0..<list.count {
            let process = list[i]
            let write = Units(bytes: Int64(process.write)).getReadableSpeed(base: process.base)
            let read = Units(bytes: Int64(process.read)).getReadableSpeed(base: process.base)
//            self.processes?.set(i, process, [read, write])
            
            print("""
                    +++++ Process list:
                    id: \(i), name: \(process), Read\(read) =>  Write: \(write)%
                """)
        }
    }
    
    internal func activityCallback(_ value: Disks) {

//        value.reversed().forEach { (drive: drive) in
//            if let view = views.first(where: { $0.name == drive.mediaName }) {
//                view.updateReadWrite(read: drive.activity.read, write: drive.activity.write)
//            }
//        }
    }
}

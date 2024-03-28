//
//  Storage.swift
//
//
//  Created by Ibrahim on 3/14/24.
//

import Cocoa
import SystemKit
import Module

/// A mudule that get a **Storage(Disk)** informations.
///
///  This informations include the ``storageInfo`` and ``topProcess``.
///
public class Storage: Module {
    
    private var capacityReader: StorageReader?
    private var activityReader: ActivityReader?
    private var processReader: ProcessReader?
    
    private var selectedDisk: String = ""
    
    public var storageInfo: StorageModel!
    public var topProcess = [StorageProcess]()
    
    public override init() {
        super.init()
        guard self.available else { return }
        
        self.capacityReader = StorageReader(.storage) { [weak self] value in
            if let value {
                self?.capacityCallback(value)
            }
        }
        self.activityReader = ActivityReader(.storage) { [weak self] value in
            if let value {
                self?.activityCallback(value)
            }
        }
        self.processReader = ProcessReader(.storage) { [weak self] value in
            if let list = value {
                self?.processCallback(list)
            }
        }
        
        self.selectedDisk = Store.shared.string(key: "\(ModuleType.storage.rawValue)_disk", defaultValue: self.selectedDisk)
        
        self.capacityReader?.read()
        
        self.capacityReader?.read()
        
        self.capacityReader?.setInterval(1)
        
        DispatchQueue.global(qos: .background).async {
            self.processReader?.read()
        }
        
        self.setReaders([self.capacityReader, self.activityReader, self.processReader])
    }
    
    private func capacityCallback(_ value: Storages) {
        
        guard let d = value.first(where: { $0.mediaName == self.selectedDisk }) ?? value.first(where: { $0.root }) else {
            return
        }
        
        storageInfo = StorageModel(
            total: d.size,
            free: d.free,
            used: d.size - d.free
        )
    }
    
}

extension Storage {
    internal func processCallback(_ list: [StorageProcess]) {
        
        topProcess = list
        
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
    
    internal func activityCallback(_ value: Storages) {

//        value.reversed().forEach { (DriveModel: drive) in
//            if let view = views.first(where: { $0.name == drive.mediaName }) {
//                view.updateReadWrite(read: drive.activity.read, write: drive.activity.write)
//            }
//        }
    }
}

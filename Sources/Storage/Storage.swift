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
    
    private var storageInfo: StorageModel?
    private var readSpeed: String = ""
    private var writeSpeed: String = ""
    
    private var topProcess = [StorageProcess]()
    
    
    // MARK: - public function
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
        self.capacityReader?.setInterval(1)

        DispatchQueue.global(qos: .background).async {
            self.processReader?.read()
        }
        
        self.setReaders([self.capacityReader, self.activityReader, self.processReader])
    }
    
    /// System storage information
    /// - Returns: an ``StorageModel`` object that shown storage information.
    public func getStorageInfo() -> StorageModel? { storageInfo }
    
    /// Storage top process
    /// - Returns: a list of ``StorageProcess`` that shown which application most use the storage.
    public func getTopProcess() -> [StorageProcess] { topProcess }
    
    /// Storage read speed
    /// - Returns: a readable string format for speed
    public func getReadSpeed() -> String { readSpeed }
    
    /// Storage write speed
    /// - Returns: a readable string format for speed
    public func getWriteSpeed() -> String { writeSpeed }
    
    // MARK: - private functions
    
    private func setStorageInfo(_ value: Storages) {
        
        guard let disk = value.first(where: { $0.root }) else {
            return
        }
        
        storageInfo = StorageModel(
            total: disk.size,
            free: disk.free,
            used: disk.size - disk.free
        )
    }
    
    private func setTopProcess(_ value: [StorageProcess]) {
        topProcess = value
    }
    
    private func setReadSpeedWithFormat(_ value: StorageProcess) {
        readSpeed = Units(bytes: Int64(value.read)).getReadableSpeed(base: value.base)
    }
    
    private func setWriteSpeedWithFormat(_ value: StorageProcess) {
        writeSpeed = Units(bytes: Int64(value.write)).getReadableSpeed(base: value.base)
    }
    
    private func capacityCallback(_ value: Storages) {
        setStorageInfo(value)
    }
    
}

extension Storage {
    internal func processCallback(_ lists: [StorageProcess]) {
        
        setTopProcess(lists)
                
        for list in lists {
            setReadSpeedWithFormat(list)
            setWriteSpeedWithFormat(list)
        }
    }
    
    internal func activityCallback(_ value: Storages) {

    }
}

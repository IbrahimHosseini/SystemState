//
//  Storage.swift
//
//
//  Created by Ibrahim on 3/14/24.
//

import Cocoa
import SystemKit
import Module

/// A module that get a **Storage(Disk)** informations.
///
///  This informations include the ``storageInfo`` and ``topProcess``.
///
public class Storage: Module {
    
    private var storageReader: StorageReader?
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
        
        self.available = true
        
        self.storageReader = StorageReader(.storage) { [weak self] value in
            if let value {
                self?.storageCallback(value)
            }
        }
        
        self.activityReader = ActivityReader(.storage) { [weak self] value in
            self?.activityCallback(value)
        }
        
        self.processReader = ProcessReader(.storage) { [weak self] value in
            if let value {
                self?.process(value)
            }
        }
        
        self.selectedDisk = Store.shared.string(key: "\(ModuleType.storage.rawValue)_disk", defaultValue: self.selectedDisk)
                
        self.storageReader?.read()
        
        self.activityReader?.read()
        DispatchQueue.global(qos: .background).async {
            self.processReader?.read()
        }
        
        self.setReaders(
            [
                self.storageReader,
                self.activityReader,
                self.processReader
            ]
        )
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
    
    private func setTopProcess(_ value: [StorageProcess]) { topProcess = value }
    
    private func setReadSpeedWithFormat(_ value: StorageProcess) {
        readSpeed = Units(bytes: Int64(value.read)).getReadableSpeed(base: value.base)
    }
    
    private func setWriteSpeedWithFormat(_ value: StorageProcess) {
        writeSpeed = Units(bytes: Int64(value.write)).getReadableSpeed(base: value.base)
    }
    
    private func storageCallback(_ value: Storages) {
        setStorageInfo(value)
    }
    
    private func process(_ lists: [StorageProcess]) {
        
        DispatchQueue.main.async { [weak self] in
                    
            self?.setTopProcess(lists)
            
            for process in lists {
                self?.setReadSpeedWithFormat(process)
                self?.setWriteSpeedWithFormat(process)
            }
        }
    }
    
    private func activityCallback(_ value: Storages?) {
        guard let value else { return }
        
    }
    
}

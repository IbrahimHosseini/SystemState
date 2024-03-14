//
//  StorageReader.swift
//  
//
//  Created by Ibrahim on 3/13/24.
//

import Cocoa
import SystemKit
import IOKit.storage

internal class StorageReader: Reader<Storages> {
    internal var list: Storages = Storages()
    
    public override func read() {
        let keys: [URLResourceKey] = [.volumeNameKey]
        let removableState = Store.shared.bool(key: "Disk_removable", defaultValue: false)
        let paths = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes])!
        
        guard let session = DASessionCreate(kCFAllocatorDefault) else {
            error("cannot create main DASessionCreate()", log: self.log)
            return
        }
        
        var active: [String] = []
        for url in paths {
            if url.pathComponents.count == 1 || (url.pathComponents.count > 1 && url.pathComponents[1] == "Volumes") {
                if let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, url as CFURL) {
                    if let diskName = DADiskGetBSDName(disk) {
                        let BSDName: String = String(cString: diskName)
                        active.append(BSDName)
                        
                        if let d = self.list.first(where: { $0.BSDName == BSDName}), let idx = self.list.index(where: { $0.BSDName == BSDName}) {
                            if d.removable && !removableState {
                                self.list.remove(at: idx)
                                continue
                            }
                            
                            if let path = d.path {
                                self.list.updateFreeSize(idx, newValue: self.freeDiskSpaceInBytes(path))
                            }
                            
                            continue
                        }
                        
                        if var d = driveDetails(disk, removableState: removableState) {
                            if let path = d.path {
                                d.free = self.freeDiskSpaceInBytes(path)
                                d.size = self.totalDiskSpaceInBytes(path)
                            }
                            self.list.append(d)
                            self.list.sort()
                        }
                    }
                }
            }
        }
        
        active.difference(from: self.list.map{ $0.BSDName }).forEach { (BSDName: String) in
            if let idx = self.list.index(where: { $0.BSDName == BSDName }) {
                self.list.remove(at: idx)
            }
        }
        
        self.callback(self.list)
    }
    
    private func freeDiskSpaceInBytes(_ path: URL) -> Int64 {
        do {
            if let url = URL(string: path.absoluteString) {
                let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
                if let capacity = values.volumeAvailableCapacityForImportantUsage, capacity != 0 {
                    return capacity
                }
            }
        } catch let err {
            error("error retrieving free space #1: \(err.localizedDescription)", log: self.log)
        }
        
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: path.path)
            if let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value {
                return freeSpace
            }
        } catch let err {
            error("error retrieving free space: \(err.localizedDescription)", log: self.log)
        }
        
        return 0
    }
    
    private func totalDiskSpaceInBytes(_ path: URL) -> Int64 {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: path.path)
            if let totalSpace = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value {
                return totalSpace
            }
        } catch let err {
            error("error retrieving total space: \(err.localizedDescription)", log: self.log)
        }
        
        return 0
    }
}

// https://opensource.apple.com/source/bless/bless-152/libbless/APFS/BLAPFSUtilities.c.auto.html
public func getDeviceIOParent(_ obj: io_registry_entry_t, level: Int) -> io_registry_entry_t? {
    var parent: io_registry_entry_t = 0
    
    if IORegistryEntryGetParentEntry(obj, kIOServicePlane, &parent) != KERN_SUCCESS {
        return nil
    }
    
    for _ in 1...level where IORegistryEntryGetParentEntry(parent, kIOServicePlane, &parent) != KERN_SUCCESS {
        IOObjectRelease(parent)
        return nil
    }
    
    return parent
}

func runProcess(path: String, args: [String] = []) -> String? {
    let task = Process()
    task.launchPath = path
    task.arguments = args
    
    let outputPipe = Pipe()
    defer {
        outputPipe.fileHandleForReading.closeFile()
    }
    task.standardOutput = outputPipe
    
    do {
        try task.run()
    } catch {
        return nil
    }
    
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    return String(decoding: outputData, as: UTF8.self)
}


//
//  ActivityReader.swift
//
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation
import SystemKit

internal class ActivityReader: Reader<Storages> {
    internal var list: Storages = Storages()
    
    override func setup() {
        self.setInterval(1)
    }
    
    public override func read() {
        let keys: [URLResourceKey] = [.volumeNameKey]
        let removableState = Store.shared.bool(key: "Disk_removable", defaultValue: false)
        let paths = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys)!
        
        guard let session = DASessionCreate(kCFAllocatorDefault) else {
            error("cannot create a DASessionCreate()", log: self.log)
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
                            
                            self.driveStats(idx, d)
                            continue
                        }
                        
                        if let d = driveDetails(disk, removableState: removableState) {
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
    
    private func driveStats(_ idx: Int, _ d: DriveModel) {
        guard let props = getIOProperties(d.parent) else {
            return
        }
        
        if let statistics = props.object(forKey: "Statistics") as? NSDictionary {
            let readBytes = statistics.object(forKey: "Bytes (Read)") as? Int64 ?? 0
            let writeBytes = statistics.object(forKey: "Bytes (Write)") as? Int64 ?? 0
            
            if d.activity.readBytes != 0 {
                self.list.updateRead(idx, newValue: readBytes - d.activity.readBytes)
            }
            if d.activity.writeBytes != 0 {
                self.list.updateWrite(idx, newValue: writeBytes - d.activity.writeBytes)
            }
            
            self.list.updateReadWrite(idx, read: readBytes, write: writeBytes)
        }
        
        return
    }
}

func driveDetails(_ disk: DADisk, removableState: Bool) -> DriveModel? {
    var d: DriveModel = DriveModel()
    
    if let bsdName = DADiskGetBSDName(disk) {
        d.BSDName = String(cString: bsdName)
    }
    
    if let diskDescription = DADiskCopyDescription(disk) {
        if let dict = diskDescription as? [String: AnyObject] {
            if let removable = dict[kDADiskDescriptionMediaRemovableKey as String] {
                if removable as! Bool {
                    if !removableState {
                        return nil
                    }
                    d.removable = true
                }
            }
            
            if let mediaName = dict[kDADiskDescriptionVolumeNameKey as String] {
                d.mediaName = mediaName as! String
                if d.mediaName == "Recovery" {
                    return nil
                }
            }
            if d.mediaName == "" {
                if let mediaName = dict[kDADiskDescriptionMediaNameKey as String] {
                    d.mediaName = mediaName as! String
                    if d.mediaName == "Recovery" {
                        return nil
                    }
                }
            }
            if let deviceModel = dict[kDADiskDescriptionDeviceModelKey as String] {
                d.model = (deviceModel as! String).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if let deviceProtocol = dict[kDADiskDescriptionDeviceProtocolKey as String] {
                d.connectionType = deviceProtocol as! String
            }
            if let volumePath = dict[kDADiskDescriptionVolumePathKey as String] {
                if let url = volumePath as? NSURL {
                    d.path = url as URL
                    
                    if let components = url.pathComponents {
                        d.root = components.count == 1
                        
                        if components.count > 1 && components[1] == "Volumes" {
                            if let name: String = url.lastPathComponent, name != "" {
                                d.mediaName = name
                            }
                        }
                    }
                }
            }
            if let volumeKind = dict[kDADiskDescriptionVolumeKindKey as String] {
                d.fileSystem = volumeKind as! String
            }
        }
    }
    
    if d.path == nil {
        return nil
    }
    
    let partitionLevel = d.BSDName.filter { "0"..."9" ~= $0 }.count
    if let parent = getDeviceIOParent(DADiskCopyIOMedia(disk), level: Int(partitionLevel)) {
        d.parent = parent
    }
    
    return d
}


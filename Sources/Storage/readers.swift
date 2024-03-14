//
//  readers.swift
//  
//
//  Created by Ibrahim on 3/13/24.
//

import Cocoa
import Kit
import IOKit.storage

public struct stats: Codable {
    var read: Int64 = 0
    var write: Int64 = 0
    
    var readBytes: Int64 = 0
    var writeBytes: Int64 = 0
}

public struct smart_t: Codable {
    var temperature: Int = 0
    var life: Int = 0
}

public struct drive: Codable {
    var parent: io_object_t = 0
    
    var mediaName: String = ""
    var BSDName: String = ""
    
    var root: Bool = false
    var removable: Bool = false
    
    var model: String = ""
    var path: URL?
    var connectionType: String = ""
    var fileSystem: String = ""
    
    var size: Int64 = 1
    var free: Int64 = 0
    
    var activity: stats = stats()
    var smart: smart_t? = nil
    
    var percentage: Double {
        let total = self.size
        let free = self.free
        var usedSpace = total - free
        if usedSpace < 0 {
            usedSpace = 0
        }
        return Double(usedSpace) / Double(total)
    }
}

public class Disks: Codable {
    private var queue: DispatchQueue = DispatchQueue(label: "eu.exelban.Stats.Disk.SynchronizedArray")
    private var _array: [drive] = []
    public var array: [drive] {
        get { self.queue.sync { self._array } }
        set { self.queue.sync { self._array = newValue } }
    }
    
    enum CodingKeys: String, CodingKey {
        case array
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.array = try container.decode(Array<drive>.self, forKey: CodingKeys.array)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(array, forKey: .array)
    }
    
    init() {}
    
    public var count: Int {
        var result = 0
        self.queue.sync { result = self.array.count }
        return result
    }
    
    // swiftlint:disable empty_count
    public var isEmpty: Bool {
        self.count == 0
    }
    // swiftlint:enable empty_count
    
    public func first(where predicate: (drive) -> Bool) -> drive? {
        return self.array.first(where: predicate)
    }
    
    public func index(where predicate: (drive) -> Bool) -> Int? {
        return self.array.firstIndex(where: predicate)
    }
    
    public func map<ElementOfResult>(_ transform: (drive) -> ElementOfResult?) -> [ElementOfResult] {
        return self.array.compactMap(transform)
    }
    
    public func reversed() -> [drive] {
        return self.array.reversed()
    }
    
    func forEach(_ body: (drive) -> Void) {
        self.array.forEach(body)
    }
    
    public func append( _ element: drive) {
        if !self.array.contains(where: {$0.BSDName == element.BSDName}) {
            self.array.append(element)
        }
    }
    
    public func remove(at index: Int) {
        self.array.remove(at: index)
    }
    
    public func sort() {
        self.array.sort{ $1.removable }
    }
    
    func updateFreeSize(_ idx: Int, newValue: Int64) {
        self.array[idx].free = newValue
    }
    
    func updateReadWrite(_ idx: Int, read: Int64, write: Int64) {
        self.array[idx].activity.readBytes = read
        self.array[idx].activity.writeBytes = write
    }
    
    func updateRead(_ idx: Int, newValue: Int64) {
        self.array[idx].activity.read = newValue
    }
    
    func updateWrite(_ idx: Int, newValue: Int64) {
        self.array[idx].activity.write = newValue
    }
    
    func updateSMARTData(_ idx: Int, smart: smart_t?) {
        self.array[idx].smart = smart
    }
}

let kIONVMeSMARTUserClientTypeID = CFUUIDGetConstantUUIDWithBytes(nil,
                                                                  0xAA, 0x0F, 0xA6, 0xF9,
                                                                  0xC2, 0xD6, 0x45, 0x7F,
                                                                  0xB1, 0x0B, 0x59, 0xA1,
                                                                  0x32, 0x53, 0x29, 0x2F
)
let kIONVMeSMARTInterfaceID = CFUUIDGetConstantUUIDWithBytes(nil,
                                                             0xCC, 0xD1, 0xDB, 0x19,
                                                             0xFD, 0x9A, 0x4D, 0xAF,
                                                             0xBF, 0x95, 0x12, 0x45,
                                                             0x4B, 0x23, 0x0A, 0xB6
)
let kIOCFPlugInInterfaceID = CFUUIDGetConstantUUIDWithBytes(nil,
                                                            0xC2, 0x44, 0xE8, 0x58,
                                                            0x10, 0x9C, 0x11, 0xD4,
                                                            0x91, 0xD4, 0x00, 0x50,
                                                            0xE4, 0xC6, 0x42, 0x6F
)

internal class CapacityReader: Reader<Disks> {
    internal var list: Disks = Disks()
    
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

internal class ActivityReader: Reader<Disks> {
    internal var list: Disks = Disks()
    
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
    
    private func driveStats(_ idx: Int, _ d: drive) {
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

private func driveDetails(_ disk: DADisk, removableState: Bool) -> drive? {
    var d: drive = drive()
    
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

struct io {
    var read: Int
    var write: Int
}

public class ProcessReader: Reader<[Disk_process]> {
    private let queue = DispatchQueue(label: "eu.exelban.Disk.processReader")
    
    private var _list: [Int32: io] = [:]
    private var list: [Int32: io] {
        get {
            self.queue.sync { self._list }
        }
        set {
            self.queue.sync { self._list = newValue }
        }
    }
    
    private var numberOfProcesses: Int {
        Store.shared.int(key: "\(ModuleType.disk.rawValue)_processes", defaultValue: 5)
    }
    
    public override func setup() {
        self.popup = true
        self.setInterval(1)
    }
    
    public override func read() {
        guard self.numberOfProcesses != 0, let output = runProcess(path: "/bin/ps", args: ["-Aceo pid,args", "-r"]) else { return }
        
        var processes: [Disk_process] = []
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
                self.list[pid] = io(read: bytesRead, write: bytesWritten)
            }
            
            if let v = self.list[pid] {
                let read = bytesRead - v.read
                let write = bytesWritten - v.write
                if read != 0 || write != 0 {
                    processes.append(Disk_process(pid: Int(pid), name: name, read: read, write: write))
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

private func runProcess(path: String, args: [String] = []) -> String? {
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


//
//  SystemKit.swift
//  
//
//  Created by Ibrahim on 3/11/24.
//

import Cocoa
import Extensions

public var isARM: Bool {
    SystemKit.shared.device.platform != .intel
}

/// A mudule that get a **SystemKit** informations.
///
///  This informations include the ``device`` and ``getModelID()``.
///
public class SystemKit {
    public static let shared = SystemKit()
    
    public var device: DeviceInfoModel = DeviceInfoModel()
    private let log: NextLog = NextLog.shared.copy(category: "SystemKit")
    
    public init() {
        let (modelID, serialNumber) = self.modelAndSerialNumber()
        if let serialNumber {
            self.device.serialNumber = serialNumber
        }
        if let modelName = modelID ?? self.getModelID(), let model = deviceDict[modelName] {
            self.device.model = model
            self.device.model.id = modelName
        } else if let model = self.getModel() {
            self.device.model = model
        }
        
        self.device.bootDate = self.bootDate()
        
        let procInfo = ProcessInfo()
        let systemVersion = procInfo.operatingSystemVersion
        
        var build = localizedString("Unknown")
        let buildArr = procInfo.operatingSystemVersionString.split(separator: "(")
        if buildArr.indices.contains(1) {
            build = buildArr[1].replacingOccurrences(of: "Build ", with: "").replacingOccurrences(of: ")", with: "")
        }
        
        let version = systemVersion.majorVersion > 10 ? "\(systemVersion.majorVersion)" : "\(systemVersion.majorVersion).\(systemVersion.minorVersion)"
        self.device.os = OSModel(name: osDict[version] ?? localizedString("Unknown"), version: systemVersion, build: build)
        
        self.device.info.cpu = self.getCPUInfo()
        self.device.info.ram = self.getRamInfo()
        self.device.info.gpu = self.getGPUInfo()
        self.device.info.disk = self.getDiskInfo()
        self.getStorageInfo()
        
        if let name = self.device.info.cpu?.name?.lowercased() {
            if name.contains("intel") {
                self.device.platform = .intel
            } else if name.contains("m1") {
                if name.contains("pro") {
                    self.device.platform = .m1Pro
                } else if name.contains("max") {
                    self.device.platform = .m1Max
                } else if name.contains("ultra") {
                    self.device.platform = .m1Ultra
                } else {
                    self.device.platform = .m1
                }
            } else if name.contains("m2") {
                if name.contains("pro") {
                    self.device.platform = .m2Pro
                } else if name.contains("max") {
                    self.device.platform = .m2Max
                } else if name.contains("ultra") {
                    self.device.platform = .m2Ultra
                } else {
                    self.device.platform = .m2
                }
            } else if name.contains("m3") {
                if name.contains("pro") {
                    self.device.platform = .m3Pro
                } else if name.contains("max") {
                    self.device.platform = .m3Max
                } else if name.contains("ultra") {
                    self.device.platform = .m3Ultra
                } else {
                    self.device.platform = .m3
                }
            }
        }
    }
    
    public func getModelID() -> String? {
        var mib = [CTL_HW, HW_MODEL]
        var size = MemoryLayout<io_name_t>.size
        
        let pointer = UnsafeMutablePointer<io_name_t>.allocate(capacity: 1)
        defer {
            pointer.deallocate()
        }
        let result = sysctl(&mib, u_int(mib.count), pointer, &size, nil, 0)
        
        if result == KERN_SUCCESS {
            return String(cString: UnsafeRawPointer(pointer).assumingMemoryBound(to: CChar.self))
        }
        
        error("error call sysctl(): \(String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error")")
        return nil
    }
    
    func modelAndSerialNumber() -> (String?, String?) {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        
        var modelIdentifier: String?
        if let property = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0), let value = property.takeUnretainedValue() as? Data {
            modelIdentifier = String(data: value, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters)
        }
        
        var serialNumber: String?
        if let property = IORegistryEntryCreateCFProperty(service, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0), let value = property.takeUnretainedValue() as? String {
            serialNumber = value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        IOObjectRelease(service)
        
        return (modelIdentifier, serialNumber)
    }
    
    func bootDate() -> Date? {
        var mib = [CTL_KERN, KERN_BOOTTIME]
        var bootTime = timeval()
        var bootTimeSize = MemoryLayout<timeval>.size
        
        let result = sysctl(&mib, UInt32(mib.count), &bootTime, &bootTimeSize, nil, 0)
        if result == KERN_SUCCESS {
            return Date(timeIntervalSince1970: Double(bootTime.tv_sec) + Double(bootTime.tv_usec) / 1_000_000.0)
        }
        
        error("error get boot time: \(String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error")")
        return nil
    }
    
    private func getCPUInfo() -> CPUModel? {
        var cpu = CPUModel()
        
        var sizeOfName = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &sizeOfName, nil, 0)
        var nameChars = [CChar](repeating: 0, count: sizeOfName)
        sysctlbyname("machdep.cpu.brand_string", &nameChars, &sizeOfName, nil, 0)
        var name = String(cString: nameChars)
        if name != "" {
            name = name.replacingOccurrences(of: "(TM)", with: "")
            name = name.replacingOccurrences(of: "(R)", with: "")
            name = name.replacingOccurrences(of: "CPU", with: "")
            name = name.replacingOccurrences(of: "@", with: "")
            
            cpu.name = name.condenseWhitespace()
        }
        
        var size = UInt32(MemoryLayout<host_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
        let hostInfo = host_basic_info_t.allocate(capacity: 1)
        defer {
            hostInfo.deallocate()
        }
        
        let result = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_info(mach_host_self(), HOST_BASIC_INFO, $0, &size)
        }
        
        if result != KERN_SUCCESS {
            error("read cores number: \(String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error")")
            return nil
        }
        
        let data = hostInfo.move()
        cpu.physicalCores = Int8(data.physical_cpu)
        cpu.logicalCores = Int8(data.logical_cpu)
        
        if let cores = getCPUCores() {
            cpu.eCores = cores.0
            cpu.pCores = cores.1
            cpu.cores = cores.2
        }
        
        return cpu
    }
    
    func getCPUCores() -> (Int32?, Int32?, [CoreModel])? {
        var iterator: io_iterator_t = io_iterator_t()
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("AppleARMPE"), &iterator)
        if result != kIOReturnSuccess {
            print("Error find AppleARMPE: " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
            return nil
        }
        
        var service: io_registry_entry_t = 1
        var list: [CoreModel] = []
        var pCores: Int32? = nil
        var eCores: Int32? = nil
        
        while service != 0 {
            service = IOIteratorNext(iterator)
            
            var entry: io_iterator_t = io_iterator_t()
            if IORegistryEntryGetChildIterator(service, kIOServicePlane, &entry) != kIOReturnSuccess {
                continue
            }
            var child: io_registry_entry_t = 1
            while child != 0 {
                child = IOIteratorNext(entry)
                guard child != 0 else {
                    continue
                }
                
                guard let name = getIOName(child),
                      let props = getIOProperties(child) else { continue }
                
                if name.matches("^cpu\\d") {
                    var type: CoreType = .unknown
                    
                    if let rawType = props.object(forKey: "cluster-type") as? Data,
                       let typ = String(data: rawType, encoding: .utf8)?.trimmed {
                        switch typ {
                        case "E":
                            type = .efficiency
                        case "P":
                            type = .performance
                        default:
                            type = .unknown
                        }
                    }
                    
                    let rawCPUId = props.object(forKey: "cpu-id") as? Data
                    let id = rawCPUId?.withUnsafeBytes { pointer in
                        return pointer.load(as: Int32.self)
                    }
                    
                    list.append(CoreModel(id: id ?? -1, name: name, type: type))
                } else if name.trimmed == "cpus" {
                    eCores = (props.object(forKey: "e-core-count") as? Data)?.withUnsafeBytes { pointer in
                        return pointer.load(as: Int32.self)
                    }
                    pCores = (props.object(forKey: "p-core-count") as? Data)?.withUnsafeBytes { pointer in
                        return pointer.load(as: Int32.self)
                    }
                }
                
                IOObjectRelease(child)
            }
            IOObjectRelease(entry)
            
            IOObjectRelease(service)
        }
        
        IOObjectRelease(iterator)
        
        return (eCores, pCores, list)
    }
    
    private func getGPUInfo() -> [GPUModel]? {
        guard let res = process(path: "/usr/sbin/system_profiler", arguments: ["SPDisplaysDataType", "-json"]) else {
            return nil
        }
        
        var list: [GPUModel] = []
        do {
            if let json = try JSONSerialization.jsonObject(with: Data(res.utf8), options: []) as? [String: Any] {
                if let arr = json["SPDisplaysDataType"] as? [[String: Any]] {
                    for obj in arr {
                        var gpu: GPUModel = GPUModel()
                        
                        gpu.name = obj["sppci_model"] as? String
                        gpu.vendor = obj["spdisplays_vendor"] as? String
                        gpu.cores = Int(obj["sppci_cores"] as? String ?? "")
                        
                        if let vram = obj["spdisplays_vram_shared"] as? String {
                            gpu.vram = vram
                        } else if let vram = obj["spdisplays_vram"] as? String {
                            gpu.vram = vram
                        }
                        
                        list.append(gpu)
                    }
                }
            }
        } catch let err as NSError {
            error("error to parse system_profiler SPDisplaysDataType: \(err.localizedDescription)")
            return nil
        }
        
        return list
    }
    
    private func getDiskInfo() -> StorageModel? {
        var disk: DADisk? = nil
        
        let keys: [URLResourceKey] = [.volumeNameKey]
        let paths = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys)!
        if let session = DASessionCreate(kCFAllocatorDefault) {
            for url in paths where url.pathComponents.count == 1 {
                disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, url as CFURL)
            }
        }
        
        if disk == nil {
            error("empty storage after fetching list")
            return nil
        }
        
        if let diskDescription = DADiskCopyDescription(disk!) {
            if let dict = diskDescription as? [String: AnyObject] {
                if let removable = dict[kDADiskDescriptionMediaRemovableKey as String] {
                    if removable as! Bool {
                        return nil
                    }
                }

                var name: String = ""
                var model: String = ""
                var size: Int64 = 0
                
                if let mediaName = dict[kDADiskDescriptionMediaNameKey as String] {
                    name = mediaName as! String
                }
                if let deviceModel = dict[kDADiskDescriptionDeviceModelKey as String] {
                    model = (deviceModel as! String).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                if let mediaSize = dict[kDADiskDescriptionMediaSizeKey as String] {
                    size = Int64(truncating: mediaSize as! NSNumber)
                }
                
                return StorageModel(name: name, model: model, size: size)
            }
        }
        
        return nil
    }
    
    public func getStorageInfo() {
//        let argument = "SPApplicationsDataType"
//        let argument = "SPHardwareDataType"
//        let argument = "SPSoftwareDataType"
        let argument = "diskutil"
        guard let res = process(path: "/usr/sbin/system_profiler", arguments: [argument, "-json"]) else {
            return
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: Data(res.utf8), options: []) as? [String: Any] {
                
                if let obj = json[argument] as? [[String: Any]], !obj.isEmpty {
                    if let items = obj[0]["_items"] as? [[String: Any]] {
                        for i in 0..<items.count {
                            let _ = items[i]
                        }
                    }
                }
                
            }
        } catch let err as NSError {
            error("error to parse system_profiler SPMemoryDataType: \(err.localizedDescription)")
        }
        
        
    }
    
    
    public func getRamInfo() -> MemoryModel? {
        guard let res = process(path: "/usr/sbin/system_profiler", arguments: ["SPMemoryDataType", "-json"]) else {
            return nil
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: Data(res.utf8), options: []) as? [String: Any] {
                var ram: MemoryModel = MemoryModel()
                
                if let obj = json["SPMemoryDataType"] as? [[String: Any]], !obj.isEmpty {
                    if let items = obj[0]["_items"] as? [[String: Any]] {
                        for i in 0..<items.count {
                            let item = items[i]
                            
                            if item["dimm_size"] as? String == "empty" {
                                continue
                            }
                            
                            var dimm: DimmModel = DimmModel()
                            dimm.type = item["dimm_type"] as? String
                            dimm.speed = item["dimm_speed"] as? String
                            dimm.size = item["dimm_size"] as? String
                            
                            if let nameValue = item["_name"] as? String {
                                let arr = nameValue.split(separator: "/")
                                if arr.indices.contains(0) {
                                    dimm.bank = Int(arr[0].filter("0123456789.".contains))
                                }
                                if arr.indices.contains(1) && arr[1].contains("Channel") {
                                    dimm.channel = arr[1].split(separator: "-")[0].replacingOccurrences(of: "Channel", with: "")
                                }
                            }
                            
                            ram.dimms.append(dimm)
                        }
                    } else if let value = obj[0]["SPMemoryDataType"] as? String {
                        ram.dimms.append(DimmModel(bank: nil, channel: nil, type: nil, size: value, speed: nil))
                    }
                }
                
                return ram
            }
        } catch let err as NSError {
            error("error to parse system_profiler SPMemoryDataType: \(err.localizedDescription)")
            return nil
        }
        
        return nil
    }
    
    private func getIcon(type: DeviceType, year: Int) -> NSImage {
        switch type {
        case .macMini:
            return NSImage(named: NSImage.Name("macMini"))!
        case .macStudio:
            return NSImage(named: NSImage.Name("macStudio"))!
        case .iMacPro:
            return NSImage(named: NSImage.Name("imacPro"))!
        case .macPro:
            switch year {
            case 2019:
                return NSImage(named: NSImage.Name("macPro2019"))!
            default:
                return NSImage(named: NSImage.Name("macPro"))!
            }
        case .iMac:
            return NSImage(named: NSImage.Name("imac"))!
        case .macbook:
            return NSImage(named: NSImage.Name("macbookAir"))!
        case .macbookAir:
            if year >= 2022 {
                return NSImage(named: NSImage.Name("macbookAir"))!
            }
            return NSImage(named: NSImage.Name("macbookAir4thGen"))!
        case .macbookPro:
            if year >= 2021 {
                return NSImage(named: NSImage.Name("macbookPro5thGen"))!
            }
            return NSImage(named: NSImage.Name("macbookPro"))!
        default:
            return NSImage(named: NSImage.Name("imacPro"))!
        }
    }
    
    private func getModel() -> DeviceModel? {
        guard let res = process(path: "/usr/sbin/system_profiler", arguments: ["SPHardwareDataType", "-json"]) else {
            return nil
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: Data(res.utf8), options: []) as? [String: Any],
               let obj = json["SPHardwareDataType"] as? [[String: Any]], !obj.isEmpty, let val = obj.first,
               let name = val["machine_name"] as? String, let model = val["machine_model"] as? String, let cpu = val["chip_type"] as? String {
                let year = Calendar.current.component(.year, from: Date())
                let type = DeviceType.all.first{ $0.rawValue.lowercased() ==  name.lowercased().removingWhitespaces() } ?? .unknown
                return DeviceModel(
                    id: model,
                    name: "\(name) (\(cpu.removedRegexMatches(pattern: "Apple ", replaceWith: "")))",
                    year: year,
                    type: type
                )
            }
        } catch let err as NSError {
            error("error to parse system_profiler SPHardwareDataType: \(err.localizedDescription)")
            return nil
        }
        
        return nil
    }
}

let deviceDict: [String: DeviceModel] = [
    // Mac Mini
    "Macmini6,1": DeviceModel(name: "Mac mini", year: 2012, type: .macMini),
    "Macmini6,2": DeviceModel(name: "Mac mini", year: 2012, type: .macMini),
    "Macmini7,1": DeviceModel(name: "Mac mini", year: 2014, type: .macMini),
    "Macmini8,1": DeviceModel(name: "Mac mini", year: 2018, type: .macMini),
    "Macmini9,1": DeviceModel(name: "Mac mini (M1)", year: 2020, type: .macMini),
    "Mac14,3": DeviceModel(name: "Mac mini (M2)", year: 2023, type: .macMini),
    "Mac14,12": DeviceModel(name: "Mac mini (M2 Pro)", year: 2023, type: .macMini),
    
    // Mac Studio
    "Mac13,1": DeviceModel(name: "Mac Studio (M1 Max)", year: 2022, type: .macStudio),
    "Mac13,2": DeviceModel(name: "Mac Studio (M1 Ultra)", year: 2022, type: .macStudio),
    "Mac14,13": DeviceModel(name: "Mac Studio (M2 Max)", year: 2023, type: .macStudio),
    "Mac14,14": DeviceModel(name: "Mac Studio (M2 Ultra)", year: 2023, type: .macStudio),
    
    // Mac Pro
    "MacPro5,1": DeviceModel(name: "Mac Pro", year: 2010, type: .macPro),
    "MacPro6,1": DeviceModel(name: "Mac Pro", year: 2016, type: .macPro),
    "MacPro7,1": DeviceModel(name: "Mac Pro", year: 2019, type: .macPro),
    "Mac14,8": DeviceModel(name: "Mac Pro (M2 Ultra)", year: 2023, type: .macPro),
    
    // iMac
    "iMac12,1": DeviceModel(name: "iMac 27-Inch", year: 2011, type: .iMac),
    "iMac13,1": DeviceModel(name: "iMac 21.5-Inch", year: 2012, type: .iMac),
    "iMac13,2": DeviceModel(name: "iMac 27-Inch", year: 2012, type: .iMac),
    "iMac14,2": DeviceModel(name: "iMac 27-Inch", year: 2013, type: .iMac),
    "iMac15,1": DeviceModel(name: "iMac 27-Inch", year: 2014, type: .iMac),
    "iMac17,1": DeviceModel(name: "iMac 27-Inch", year: 2015, type: .iMac),
    "iMac18,1": DeviceModel(name: "iMac 21.5-Inch", year: 2017, type: .iMac),
    "iMac18,2": DeviceModel(name: "iMac 21.5-Inch", year: 2017, type: .iMac),
    "iMac18,3": DeviceModel(name: "iMac 27-Inch", year: 2017, type: .iMac),
    "iMac19,1": DeviceModel(name: "iMac 27-Inch", year: 2019, type: .iMac),
    "iMac20,1": DeviceModel(name: "iMac 27-Inch", year: 2020, type: .iMac),
    "iMac20,2": DeviceModel(name: "iMac 27-Inch", year: 2020, type: .iMac),
    "iMac21,1": DeviceModel(name: "iMac 24-Inch (M1)", year: 2021, type: .iMac),
    "iMac21,2": DeviceModel(name: "iMac 24-Inch (M1)", year: 2021, type: .iMac),
    "Mac15,4": DeviceModel(name: "iMac 24-Inch (M3, 8 CPU/8 GPU)", year: 2023, type: .iMac),
    "Mac15,5": DeviceModel(name: "iMac 24-Inch (M3, 8 CPU/10 GPU)", year: 2023, type: .iMac),
    
    // iMac Pro
    "iMacPro1,1": DeviceModel(name: "iMac Pro", year: 2017, type: .iMacPro),
    
    // MacBook
    "MacBook8,1": DeviceModel(name: "MacBook", year: 2015, type: .macbook),
    "MacBook9,1": DeviceModel(name: "MacBook", year: 2016, type: .macbook),
    "MacBook10,1": DeviceModel(name: "MacBook", year: 2017, type: .macbook),
    
    // MacBook Air
    "MacBookAir5,1": DeviceModel(name: "MacBook Air 11\"", year: 2012, type: .macbookAir),
    "MacBookAir5,2": DeviceModel(name: "MacBook Air 13\"", year: 2012, type: .macbookAir),
    "MacBookAir6,1": DeviceModel(name: "MacBook Air 11\"", year: 2014, type: .macbookAir),
    "MacBookAir6,2": DeviceModel(name: "MacBook Air 13\"", year: 2014, type: .macbookAir),
    "MacBookAir7,1": DeviceModel(name: "MacBook Air 11\"", year: 2015, type: .macbookAir),
    "MacBookAir7,2": DeviceModel(name: "MacBook Air 13\"", year: 2015, type: .macbookAir),
    "MacBookAir8,1": DeviceModel(name: "MacBook Air 13\"", year: 2018, type: .macbookAir),
    "MacBookAir8,2": DeviceModel(name: "MacBook Air 13\"", year: 2019, type: .macbookAir),
    "MacBookAir9,1": DeviceModel(name: "MacBook Air 13\"", year: 2020, type: .macbookAir),
    "MacBookAir10,1": DeviceModel(name: "MacBook Air 13\" (M1)", year: 2020, type: .macbookAir),
    "Mac14,2": DeviceModel(name: "MacBook Air 13\" (M2)", year: 2022, type: .macbookAir),
    "Mac14,15": DeviceModel(name: "MacBook Air 15\" (M2)", year: 2022, type: .macbookAir),
    
    // MacBook Pro
    "MacBookPro9,1": DeviceModel(name: "MacBook Pro 15\"", year: 2012, type: .macbookPro),
    "MacBookPro9,2": DeviceModel(name: "MacBook Pro 13\"", year: 2012, type: .macbookPro),
    "MacBookPro10,1": DeviceModel(name: "MacBook Pro 15\"", year: 2012, type: .macbookPro),
    "MacBookPro10,2": DeviceModel(name: "MacBook Pro 13\"", year: 2012, type: .macbookPro),
    "MacBookPro11,1": DeviceModel(name: "MacBook Pro 13\"", year: 2014, type: .macbookPro),
    "MacBookPro11,2": DeviceModel(name: "MacBook Pro 15\"", year: 2014, type: .macbookPro),
    "MacBookPro11,3": DeviceModel(name: "MacBook Pro 15\"", year: 2014, type: .macbookPro),
    "MacBookPro11,4": DeviceModel(name: "MacBook Pro 15\"", year: 2015, type: .macbookPro),
    "MacBookPro11,5": DeviceModel(name: "MacBook Pro 15\"", year: 2015, type: .macbookPro),
    "MacBookPro12,1": DeviceModel(name: "MacBook Pro 13\"", year: 2015, type: .macbookPro),
    "MacBookPro13,1": DeviceModel(name: "MacBook Pro 13\"", year: 2016, type: .macbookPro),
    "MacBookPro13,2": DeviceModel(name: "MacBook Pro 13\"", year: 2016, type: .macbookPro),
    "MacBookPro13,3": DeviceModel(name: "MacBook Pro 15\"", year: 2016, type: .macbookPro),
    "MacBookPro14,1": DeviceModel(name: "MacBook Pro 13\"", year: 2017, type: .macbookPro),
    "MacBookPro14,2": DeviceModel(name: "MacBook Pro 13\"", year: 2017, type: .macbookPro),
    "MacBookPro14,3": DeviceModel(name: "MacBook Pro 15\"", year: 2017, type: .macbookPro),
    "MacBookPro15,1": DeviceModel(name: "MacBook Pro 15\"", year: 2018, type: .macbookPro),
    "MacBookPro15,2": DeviceModel(name: "MacBook Pro 13\"", year: 2019, type: .macbookPro),
    "MacBookPro15,3": DeviceModel(name: "MacBook Pro 15\"", year: 2019, type: .macbookPro),
    "MacBookPro15,4": DeviceModel(name: "MacBook Pro 13\"", year: 2019, type: .macbookPro),
    "MacBookPro16,1": DeviceModel(name: "MacBook Pro 16\"", year: 2019, type: .macbookPro),
    "MacBookPro16,2": DeviceModel(name: "MacBook Pro 13\"", year: 2019, type: .macbookPro),
    "MacBookPro16,3": DeviceModel(name: "MacBook Pro 13\"", year: 2020, type: .macbookPro),
    "MacBookPro17,1": DeviceModel(name: "MacBook Pro 13\" (M1)", year: 2020, type: .macbookPro),
    "MacBookPro18,1": DeviceModel(name: "MacBook Pro 16\" (M1 Pro)", year: 2021, type: .macbookPro),
    "MacBookPro18,2": DeviceModel(name: "MacBook Pro 16\" (M1 Max)", year: 2021, type: .macbookPro),
    "MacBookPro18,3": DeviceModel(name: "MacBook Pro 14\" (M1 Pro)", year: 2021, type: .macbookPro),
    "MacBookPro18,4": DeviceModel(name: "MacBook Pro 14\" (M1 Max)", year: 2021, type: .macbookPro),
    "Mac14,7": DeviceModel(name: "MacBook Pro 13\" (M2)", year: 2022, type: .macbookPro),
    "Mac14,5": DeviceModel(name: "MacBook Pro 14\" (M2 Max)", year: 2023, type: .macbookPro),
    "Mac14,6": DeviceModel(name: "MacBook Pro 16\" (M2 Max)", year: 2023, type: .macbookPro),
    "Mac14,9": DeviceModel(name: "MacBook Pro 14\" (M2 Pro)", year: 2023, type: .macbookPro),
    "Mac14,10": DeviceModel(name: "MacBook Pro 16\" (M2 Pro)", year: 2023, type: .macbookPro),
    "Mac15,3": DeviceModel(name: "MacBook Pro 14\" (M3, 8 CPU/10 GPU)", year: 2023, type: .macbookPro),
    "Mac15,6": DeviceModel(name: "MacBook Pro 14\" (M3 Pro)", year: 2023, type: .macbookPro),
    "Mac15,7": DeviceModel(name: "MacBook Pro 16\" (M3 Pro, 12 CPU/18 GPU)", year: 2023, type: .macbookPro),
    "Mac15,8": DeviceModel(name: "MacBook Pro 14\" (M3 Max, 16 CPU/40 GPU)", year: 2023, type: .macbookPro),
    "Mac15,9": DeviceModel(name: "MacBook Pro 16\" (M3 Max, 16 CPU/40 GPU)", year: 2023, type: .macbookPro),
    "Mac15,10": DeviceModel(name: "MacBook Pro 14\" (M3 Max, 14 CPU/30 GPU)", year: 2023, type: .macbookPro),
    "Mac15,11": DeviceModel(name: "MacBook Pro 16\" (M3 Max, 14 CPU/30 GPU)", year: 2023, type: .macbookPro)
]

let osDict: [String: String] = [
    "10.13": "High Sierra",
    "10.14": "Mojave",
    "10.15": "Catalina",
    "11": "Big Sur",
    "12": "Monterey",
    "13": "Ventura",
    "14": "Sonoma"
]


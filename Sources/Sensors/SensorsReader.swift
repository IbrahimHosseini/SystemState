//
//  SensorsReader.swift
//
//
//  Created by Ibrahim on 3/18/24.
//

import SystemKit
import Cocoa
import SMC
import Bridge

internal class SensorsReader: Reader<SensorsListService> {
    static let HIDtypes: [SensorType] = [.temperature, .voltage]
    
    internal var list: SensorsListService = SensorsListService()
    
    private var lastRead: Date = Date()
    private let firstRead: Date = Date()
    
    private var HIDState: Bool {
        Store.shared.bool(key: "Sensors_hid", defaultValue: false)
    }
    private var unknownSensorsState: Bool
    
    init(callback: @escaping (T?) -> Void = {_ in }) {
        self.unknownSensorsState = Store.shared.bool(key: "Sensors_unknown", defaultValue: false)
        super.init(.sensors, callback: callback)
        self.list.sensors = self.sensors()
    }
    
    private func sensors() -> [SensorService] {
        var available: [String] = SMC.shared.getAllKeys()
        var list: [SensorService] = []
        var sensorsList = SensorsList
        
        if let platform = SystemKit.shared.device.platform {
            sensorsList = sensorsList.filter({ $0.platforms.contains(platform) })
        }
        
        if let count = SMC.shared.getValue("FNum") {
            list += self.loadFans(Int(count))
        }
        
        available = available.filter({ (key: String) -> Bool in
            switch key.prefix(1) {
            case "T", "V", "P", "I": return true
            default: return false
            }
        })
        
        sensorsList.forEach { (s: SensorModel) in
            if let idx = available.firstIndex(where: { $0 == s.key }) {
                list.append(s)
                available.remove(at: idx)
            }
        }
        sensorsList.filter{ $0.key.contains("%") }.forEach { (s: SensorModel) in
            var index = 1
            for i in 0..<10 {
                let key = s.key.replacingOccurrences(of: "%", with: "\(i)")
                if let idx = available.firstIndex(where: { $0 == key }) {
                    var sensor = s.copy()
                    sensor.key = key
                    sensor.name = s.name.replacingOccurrences(of: "%", with: "\(index)")
                    
                    list.append(sensor)
                    available.remove(at: idx)
                    index += 1
                }
            }
        }
        available.forEach { (key: String) in
            var type: SensorType? = nil
            switch key.prefix(1) {
            case "T": type = .temperature
            case "V": type = .voltage
            case "P": type = .power
            case "I": type = .current
            default: type = nil
            }
            if let t = type {
                list.append(SensorModel(key: key, name: key, group: .unknown, type: t, platforms: []))
            }
        }
        
        for sensor in list {
            if let newValue = SMC.shared.getValue(sensor.key) {
                if let idx = list.firstIndex(where: { $0.key == sensor.key }) {
                    list[idx].value = newValue
                }
            }
        }
        
        var results: [SensorService] = []
        results += list.filter({ (s: SensorService) -> Bool in
            if s.type == .temperature && (s.value == 0 || s.value > 110) {
                return false
            } else if s.type == .current && s.value > 100 {
                return false
            }
            return true
        })
        
        #if arch(arm64)
        if self.HIDState {
            results += self.initHIDSensors()
        }
        #endif
        results += self.initCalculatedSensors(results)
        
        return results
    }
    
    public override func read() {
        for i in self.list.sensors.indices {
            guard self.list.sensors[i].group != .hid && !self.list.sensors[i].isComputed else { continue }
            if !self.unknownSensorsState && self.list.sensors[i].group == .unknown { continue }
            
            var newValue = SMC.shared.getValue(self.list.sensors[i].key) ?? 0
            if self.list.sensors[i].type == .temperature && self.list.sensors[i].group == .CPU &&
                (newValue < 10 || newValue > 120) { // fix for m2 broken sensors
                newValue = self.list.sensors[i].value
            }
            self.list.sensors[i].value = newValue
        }
        
        var cpuSensors = self.list.sensors.filter({ $0.group == .CPU && $0.type == .temperature && $0.average }).map{ $0.value }
        var gpuSensors = self.list.sensors.filter({ $0.group == .GPU && $0.type == .temperature && $0.average }).map{ $0.value }
        let fanSensors = self.list.sensors.filter({ $0.type == .fan && !$0.isComputed })
        
        #if arch(arm64)
        if self.HIDState {
            for typ in SensorsReader.HIDtypes {
                let (page, usage, type) = self.m1Preset(type: typ)
                AppleSiliconSensors(page, usage, type).forEach { (key, value) in
                    guard let key = key as? String, let value = value as? Double, value < 300 && value >= 0 else {
                        return
                    }
                    
                    if let idx = self.list.sensors.firstIndex(where: { $0.group == .hid && $0.key == key }) {
                        self.list.sensors[idx].value = value
                    }
                }
            }
            
            cpuSensors += self.list.sensors.filter({ $0.key.hasPrefix("pACC MTR Temp") || $0.key.hasPrefix("eACC MTR Temp") }).map{ $0.value }
            gpuSensors += self.list.sensors.filter({ $0.key.hasPrefix("GPU MTR Temp") }).map{ $0.value }
            
            let socSensors = self.list.sensors.filter({ $0.key.hasPrefix("SOC MTR Temp") }).map{ $0.value }
            if !socSensors.isEmpty {
                if let idx = self.list.sensors.firstIndex(where: { $0.key == "Average SOC" }) {
                    self.list.sensors[idx].value = socSensors.reduce(0, +) / Double(socSensors.count)
                }
                if let max = socSensors.max() {
                    if let idx = self.list.sensors.firstIndex(where: { $0.key == "Hottest SOC" }) {
                        self.list.sensors[idx].value = max
                    }
                }
            }
        }
        #endif
        
        if !cpuSensors.isEmpty {
            if let idx = self.list.sensors.firstIndex(where: { $0.key == "Average CPU" }) {
                self.list.sensors[idx].value = cpuSensors.reduce(0, +) / Double(cpuSensors.count)
            }
            if let max = cpuSensors.max() {
                if let idx = self.list.sensors.firstIndex(where: { $0.key == "Hottest CPU" }) {
                    self.list.sensors[idx].value = max
                }
            }
        }
        if !gpuSensors.isEmpty {
            if let idx = self.list.sensors.firstIndex(where: { $0.key == "Average GPU" }) {
                self.list.sensors[idx].value = gpuSensors.reduce(0, +) / Double(gpuSensors.count)
            }
            if let max = gpuSensors.max() {
                if let idx = self.list.sensors.firstIndex(where: { $0.key == "Hottest GPU" }) {
                    self.list.sensors[idx].value = max
                }
            }
        }
        if !fanSensors.isEmpty && fanSensors.count > 1 {
            if let f = fanSensors.max(by: { $0.value < $1.value }) as? Fan {
                if let idx = self.list.sensors.firstIndex(where: { $0.key == "Fastest fan" }) {
                    if var fan = self.list.sensors[idx] as? Fan {
                        fan.value = f.value
                        fan.minSpeed = f.minSpeed
                        fan.maxSpeed = f.maxSpeed
                        self.list.sensors[idx] = fan
                    }
                }
            }
        }
        
        if let PSTRSensor = self.list.sensors.first(where: { $0.key == "PSTR"}), PSTRSensor.value > 0 {
            let sinceLastRead = Date().timeIntervalSince(self.lastRead)
            let sinceFirstRead = Date().timeIntervalSince(self.firstRead)
            
            if let totalIdx = self.list.sensors.firstIndex(where: {$0.key == "Total System Consumption"}), sinceLastRead > 0 {
                self.list.sensors[totalIdx].value += PSTRSensor.value * sinceLastRead / 3600
                if let avgIdx = self.list.sensors.firstIndex(where: {$0.key == "Average System Total"}), sinceFirstRead > 0 {
                    self.list.sensors[avgIdx].value = self.list.sensors[totalIdx].value * 3600 / sinceFirstRead
                }
            }
            
            self.lastRead = Date()
        }
        
        // cut off low dc in voltage
        if let idx = self.list.sensors.firstIndex(where: { $0.key == "VD0R" }), self.list.sensors[idx].value < 0.4 {
            self.list.sensors[idx].value = 0
        }
        // cut off low dc in current
        if let idx = self.list.sensors.firstIndex(where: { $0.key == "ID0R" }), self.list.sensors[idx].value < 0.05 {
            self.list.sensors[idx].value = 0
        }
        
        self.callback(self.list)
    }
    
    private func initCalculatedSensors(_ sensors: [SensorService]) -> [SensorService] {
        var list: [SensorService] = []
        
        var cpuSensors = sensors.filter({ $0.group == .CPU && $0.type == .temperature && $0.average }).map{ $0.value }
        var gpuSensors = sensors.filter({ $0.group == .GPU && $0.type == .temperature && $0.average }).map{ $0.value }
        
        #if arch(arm64)
        if self.HIDState {
            cpuSensors += sensors.filter({ $0.key.hasPrefix("pACC MTR Temp") || $0.key.hasPrefix("eACC MTR Temp") }).map{ $0.value }
            gpuSensors += sensors.filter({ $0.key.hasPrefix("GPU MTR Temp") }).map{ $0.value }
        }
        #endif
        
        let fanSensors = sensors.filter({ $0.type == .fan && !$0.isComputed })
        
        if !cpuSensors.isEmpty {
            let value = cpuSensors.reduce(0, +) / Double(cpuSensors.count)
            list.append(SensorModel(key: "Average CPU", name: "Average CPU", value: value, group: .CPU, type: .temperature, platforms: Platform.all, isComputed: true))
            if let max = cpuSensors.max() {
                list.append(SensorModel(key: "Hottest CPU", name: "Hottest CPU", value: max, group: .CPU, type: .temperature, platforms: Platform.all, isComputed: true))
            }
        }
        if !gpuSensors.isEmpty {
            let value = gpuSensors.reduce(0, +) / Double(gpuSensors.count)
            list.append(SensorModel(key: "Average GPU", name: "Average GPU", value: value, group: .GPU, type: .temperature, platforms: Platform.all, isComputed: true))
            if let max = gpuSensors.max() {
                list.append(SensorModel(key: "Hottest GPU", name: "Hottest GPU", value: max, group: .GPU, type: .temperature, platforms: Platform.all, isComputed: true))
            }
        }
        if !fanSensors.isEmpty && fanSensors.count > 1 {
            if let f = fanSensors.max(by: { $0.value < $1.value }) as? Fan {
                list.append(Fan(id: -1, key: "Fastest fan", name: "Fastest fan", minSpeed: f.minSpeed, maxSpeed: f.maxSpeed, value: f.value, mode: .automatic, isComputed: true))
            }
        }
        
        // Init total power since launched, only if Total Power sensor is available
        if sensors.contains(where: { $0.key == "PSTR"}) {
            list.append(SensorModel(key: "Total System Consumption", name: "Total System Consumption", value: 0, group: .sensor, type: .energy, platforms: Platform.all, isComputed: true))
            list.append(SensorModel(key: "Average System Total", name: "Average System Total", value: 0, group: .sensor, type: .power, platforms: Platform.all, isComputed: true))
        }
        
        return list.filter({ (s: SensorService) -> Bool in
            switch s.type {
            case .temperature:
                return s.value < 110 && s.value >= 0
            case .voltage:
                return s.value < 300 && s.value >= 0
            case .current:
                return s.value < 100 && s.value >= 0
            default: return true
            }
        }).sorted { $0.key.lowercased() < $1.key.lowercased() }
    }
    
    public func unknownCallback() {
        self.unknownSensorsState = Store.shared.bool(key: "Sensors_unknown", defaultValue: false)
    }
}

// MARK: - Fans

extension SensorsReader {
    private func loadFans(_ count: Int) -> [SensorService] {
        debug("Found \(Int(count)) fans", log: self.log)
        
        var list: [Fan] = []
        for i in 0..<Int(count) {
            var name = SMC.shared.getStringValue("F\(i)ID")
            var mode: FanMode
            
            if name == nil && count == 2 {
                switch i {
                case 0:
                    name = localizedString("Left fan")
                case 1:
                    name = localizedString("Right fan")
                default: break
                }
            }
            
            if let md = SMC.shared.getValue("F\(i)Md") {
                mode = FanMode(rawValue: Int(md)) ?? .automatic
            } else {
                mode = self.getFanMode(i)
            }
            
            list.append(Fan(
                id: i,
                key: "F\(i)Ac",
                name: name ?? "\(localizedString("Fan")) #\(i)",
                minSpeed: SMC.shared.getValue("F\(i)Mn") ?? 1,
                maxSpeed: SMC.shared.getValue("F\(i)Mx") ?? 1,
                value: SMC.shared.getValue("F\(i)Ac") ?? 0,
                mode: mode
            ))
        }
        
        return list
    }
    
    private func getFanMode(_ id: Int) -> FanMode {
        let fansMode: Int = Int(SMC.shared.getValue("FS! ") ?? 0)
        var mode: FanMode = .automatic
        
        if fansMode == 0 {
            mode = .automatic
        } else if fansMode == 3 {
            mode = .forced
        } else if fansMode == 1 && id == 0 {
            mode = .forced
        } else if fansMode == 2 && id == 1 {
            mode = .forced
        }
        
        return mode
    }
}

// MARK: - HID sensors

extension SensorsReader {
    private func m1Preset(type: SensorType) -> (Int32, Int32, Int32) {
        var page: Int32 = 0
        var usage: Int32 = 0
        var eventType: Int32 = kIOHIDEventTypeTemperature
        
        switch type {
        case .temperature:
            page = 0xff00
            usage = 0x0005
            eventType = kIOHIDEventTypeTemperature
        case .current:
            page = 0xff08
            usage = 0x0002
            eventType = kIOHIDEventTypePower
        case .voltage:
            page = 0xff08
            usage = 0x0003
            eventType = kIOHIDEventTypePower
        case .power, .energy, .fan: break
        }
        
        return (page, usage, eventType)
    }
    
    private func initHIDSensors() -> [SensorModel] {
        var list: [SensorModel] = []
        
        for typ in SensorsReader.HIDtypes {
            let (page, usage, type) = self.m1Preset(type: typ)
            if let sensors = AppleSiliconSensors(page, usage, type) {
                sensors.forEach { (key, value) in
                    guard let key = key as? String, let value = value as? Double else {
                        return
                    }
                    var name: String = key
                    
                    HIDSensorsList.forEach { (s: SensorModel) in
                        if s.key.contains("%") {
                            var index = 1
                            for i in 0..<64 {
                                if s.key.replacingOccurrences(of: "%", with: "\(i)") == key {
                                    name = s.name.replacingOccurrences(of: "%", with: "\(index)")
                                }
                                index += 1
                            }
                        } else if s.key == key {
                            name = s.name
                        }
                    }
                    
                    list.append(
                        SensorModel(
                            key: key,
                            name: name,
                            value: value,
                            group: .hid,
                            type: typ,
                            platforms: Platform.all
                        )
                    )
                }
            }
        }
        
        let socSensors = list.filter({ $0.key.hasPrefix("SOC MTR Temp") }).map{ $0.value }
        if !socSensors.isEmpty {
            let value = socSensors.reduce(0, +) / Double(socSensors.count)
            list.append(SensorModel(key: "Average SOC", name: "Average SOC", value: value, group: .hid, type: .temperature, platforms: Platform.all))
            if let max = socSensors.max() {
                list.append(SensorModel(key: "Hottest SOC", name: "Hottest SOC", value: max, group: .hid, type: .temperature, platforms: Platform.all))
            }
        }
        
        return list.filter({ (s: SensorService) -> Bool in
            switch s.type {
            case .temperature:
                return s.value < 110 && s.value >= 0
            case .voltage:
                return s.value < 300 && s.value >= 0
            case .current:
                return s.value < 100 && s.value >= 0
            default: return true
            }
        }).sorted { $0.key.lowercased() < $1.key.lowercased() }
    }
    
    public func HIDCallback() {
        if self.HIDState {
            self.list.sensors += self.initHIDSensors()
        } else {
            self.list.sensors = self.list.sensors.filter({ $0.group != .hid })
        }
    }
}


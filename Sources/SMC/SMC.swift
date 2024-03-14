//
//  SMC.swift
//
//
//  Created by Ibrahim on 3/12/24.
//

import Foundation
import IOKit
import Extensions

public class SMC {
    public static let shared = SMC()
    private var conn: io_connect_t = 0
    
    public init() {
        var result: kern_return_t
        var iterator: io_iterator_t = 0
        let device: io_object_t
        
        let matchingDictionary: CFMutableDictionary = IOServiceMatching("AppleSMC")
        result = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDictionary, &iterator)
        if result != kIOReturnSuccess {
            print("Error IOServiceGetMatchingServices(): " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
            return
        }
        
        device = IOIteratorNext(iterator)
        IOObjectRelease(iterator)
        if device == 0 {
            print("Error IOIteratorNext(): " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
            return
        }
        
        result = IOServiceOpen(device, mach_task_self_, 0, &conn)
        IOObjectRelease(device)
        if result != kIOReturnSuccess {
            print("Error IOServiceOpen(): " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
            return
        }
    }
    
    deinit {
        let result = self.close()
        if result != kIOReturnSuccess {
            print("error close smc connection: " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
        }
    }
    
    public func close() -> kern_return_t {
        return IOServiceClose(conn)
    }
    
    public func getValue(_ key: String) -> Double? {
        var result: kern_return_t = 0
        var val: SMCValModel = SMCValModel(key)
        
        result = read(&val)
        if result != kIOReturnSuccess {
            print("Error read(\(key)): " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
            return nil
        }
        
        if val.dataSize > 0 {
            if val.bytes.first(where: { $0 != 0 }) == nil && val.key != "FS! " && val.key != "F0Md" && val.key != "F1Md" {
                return nil
            }
            
            switch val.dataType {
            case SMCDataType.UI8.rawValue:
                return Double(val.bytes[0])
            case SMCDataType.UI16.rawValue:
                return Double(UInt16(bytes: (val.bytes[0], val.bytes[1])))
            case SMCDataType.UI32.rawValue:
                return Double(UInt32(bytes: (val.bytes[0], val.bytes[1], val.bytes[2], val.bytes[3])))
            case SMCDataType.SP1E.rawValue:
                let result: Double = Double(UInt16(val.bytes[0]) * 256 + UInt16(val.bytes[1]))
                return Double(result / 16384)
            case SMCDataType.SP3C.rawValue:
                let result: Double = Double(UInt16(val.bytes[0]) * 256 + UInt16(val.bytes[1]))
                return Double(result / 4096)
            case SMCDataType.SP4B.rawValue:
                let result: Double = Double(UInt16(val.bytes[0]) * 256 + UInt16(val.bytes[1]))
                return Double(result / 2048)
            case SMCDataType.SP5A.rawValue:
                let result: Double = Double(UInt16(val.bytes[0]) * 256 + UInt16(val.bytes[1]))
                return Double(result / 1024)
            case SMCDataType.SP69.rawValue:
                let result: Double = Double(UInt16(val.bytes[0]) * 256 + UInt16(val.bytes[1]))
                return Double(result / 512)
            case SMCDataType.SP78.rawValue:
                let intValue: Double = Double(Int(val.bytes[0]) * 256 + Int(val.bytes[1]))
                return Double(intValue / 256)
            case SMCDataType.SP87.rawValue:
                let intValue: Double = Double(Int(val.bytes[0]) * 256 + Int(val.bytes[1]))
                return Double(intValue / 128)
            case SMCDataType.SP96.rawValue:
                let intValue: Double = Double(Int(val.bytes[0]) * 256 + Int(val.bytes[1]))
                return Double(intValue / 64)
            case SMCDataType.SPB4.rawValue:
                let intValue: Double = Double(Int(val.bytes[0]) * 256 + Int(val.bytes[1]))
                return Double(intValue / 16)
            case SMCDataType.SPF0.rawValue:
                let intValue: Double = Double(Int(val.bytes[0]) * 256 + Int(val.bytes[1]))
                return intValue
            case SMCDataType.FLT.rawValue:
                let value: Float? = Float(val.bytes)
                if value != nil {
                    return Double(value!)
                }
                return nil
            case SMCDataType.FPE2.rawValue:
                return Double(Int(fromFPE2: (val.bytes[0], val.bytes[1])))
            default:
                return nil
            }
        }
        
        return nil
    }
    
    public func getStringValue(_ key: String) -> String? {
        var result: kern_return_t = 0
        var val: SMCValModel = SMCValModel(key)
        
        result = read(&val)
        if result != kIOReturnSuccess {
            print("Error read(): " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
            return nil
        }
        
        if val.dataSize > 0 {
            if val.bytes.first(where: { $0 != 0}) == nil {
                return nil
            }
            
            switch val.dataType {
            case SMCDataType.FDS.rawValue:
                let c1  = String(UnicodeScalar(val.bytes[4]))
                let c2  = String(UnicodeScalar(val.bytes[5]))
                let c3  = String(UnicodeScalar(val.bytes[6]))
                let c4  = String(UnicodeScalar(val.bytes[7]))
                let c5  = String(UnicodeScalar(val.bytes[8]))
                let c6  = String(UnicodeScalar(val.bytes[9]))
                let c7  = String(UnicodeScalar(val.bytes[10]))
                let c8  = String(UnicodeScalar(val.bytes[11]))
                let c9  = String(UnicodeScalar(val.bytes[12]))
                let c10 = String(UnicodeScalar(val.bytes[13]))
                let c11 = String(UnicodeScalar(val.bytes[14]))
                let c12 = String(UnicodeScalar(val.bytes[15]))
                
                return (c1 + c2 + c3 + c4 + c5 + c6 + c7 + c8 + c9 + c10 + c11 + c12).trimmingCharacters(in: .whitespaces)
            default:
                print("unsupported data type \(val.dataType) for key: \(key)")
                return nil
            }
        }
        
        return nil
    }
    
    public func getAllKeys() -> [String] {
        var list: [String] = []
        
        let keysNum: Double? = self.getValue("#KEY")
        if keysNum == nil {
            print("ERROR no keys count found")
            return list
        }
        
        var result: kern_return_t = 0
        var input: SMCKeyDataModel = SMCKeyDataModel()
        var output: SMCKeyDataModel = SMCKeyDataModel()
        
        for i in 0...Int(keysNum!) {
            input = SMCKeyDataModel()
            output = SMCKeyDataModel()
            
            input.data8 = SMCKeys.readIndex.rawValue
            input.data32 = UInt32(i)
            
            result = call(SMCKeys.kernelIndex.rawValue, input: &input, output: &output)
            if result != kIOReturnSuccess {
                continue
            }
            
            list.append(output.key.toString())
        }
        
        return list
    }
    
    public func write(_ key: String, _ newValue: Int) -> kern_return_t {
        var value = SMCValModel(key)
        value.dataSize = 2
        value.bytes = [UInt8(newValue >> 6), UInt8((newValue << 2) ^ ((newValue >> 6) << 8)), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                       UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                       UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                       UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                       UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                       UInt8(0), UInt8(0)]
        
        return write(value)
    }
    
    // MARK: - fans
    
    public func setFanMode(_ id: Int, mode: FanMode) {
        if self.getValue("F\(id)Md") != nil {
            var result: kern_return_t = 0
            var value = SMCValModel("F\(id)Md")
            
            result = read(&value)
            if result != kIOReturnSuccess {
                print("Error read fan mode: " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
                return
            }
            
            value.bytes = [UInt8(mode.rawValue), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                                   UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                                   UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                                   UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                                   UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                                   UInt8(0), UInt8(0)]
            
            result = write(value)
            if result != kIOReturnSuccess {
                print("Error write: " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
                return
            }
        }
        
        let fansMode = Int(self.getValue("FS! ") ?? 0)
        var newMode: UInt8 = 0
        
        if fansMode == 0 && id == 0 && mode == .forced {
            newMode = 1
        } else if fansMode == 0 && id == 1 && mode == .forced {
            newMode = 2
        } else if fansMode == 1 && id == 0 && mode == .automatic {
            newMode = 0
        } else if fansMode == 1 && id == 1 && mode == .forced {
            newMode = 3
        } else if fansMode == 2 && id == 1 && mode == .automatic {
            newMode = 0
        } else if fansMode == 2 && id == 0 && mode == .forced {
            newMode = 3
        } else if fansMode == 3 && id == 0 && mode == .automatic {
            newMode = 2
        } else if fansMode == 3 && id == 1 && mode == .automatic {
            newMode = 1
        }
        
        if fansMode == newMode {
            return
        }
        
        var result: kern_return_t = 0
        var value = SMCValModel("FS! ")
        
        result = read(&value)
        if result != kIOReturnSuccess {
            print("Error read fan mode: " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
            return
        }
        
        value.bytes = [0, newMode, UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                       UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                       UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                       UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                       UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                       UInt8(0), UInt8(0)]
        
        result = write(value)
        if result != kIOReturnSuccess {
            print("Error write: " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
            return
        }
    }
    
    public func setFanSpeed(_ id: Int, speed: Int) {
        let maxSpeed = Int(self.getValue("F\(id)Mx") ?? 4000)
        
        if speed > maxSpeed {
            print("new fan speed (\(speed)) is more than maximum speed (\(maxSpeed))")
            return
        }
        
        var result: kern_return_t = 0
        var value = SMCValModel("F\(id)Tg")
        
        result = read(&value)
        if result != kIOReturnSuccess {
            print("Error read fan value: " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
            return
        }
        
        if value.dataType == "flt " {
            let bytes = Float(speed).bytes
            value.bytes[0] = bytes[0]
            value.bytes[1] = bytes[1]
            value.bytes[2] = bytes[2]
            value.bytes[3] = bytes[3]
        } else if value.dataType == "fpe2" {
            value.bytes[0] = UInt8(speed >> 6)
            value.bytes[1] = UInt8((speed << 2) ^ ((speed >> 6) << 8))
            value.bytes[2] = UInt8(0)
            value.bytes[3] = UInt8(0)
        }
        
        result = write(value)
        if result != kIOReturnSuccess {
            print("Error write: " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
            return
        }
    }
    
    public func resetFans() {
        var value = SMCValModel("FS! ")
        value.dataSize = 2
        
        let result = write(value)
        if result != kIOReturnSuccess {
            print("Error write: " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
        }
    }
    
    // MARK: - internal functions
    
    private func read(_ value: UnsafeMutablePointer<SMCValModel>) -> kern_return_t {
        var result: kern_return_t = 0
        var input = SMCKeyDataModel()
        var output = SMCKeyDataModel()
        
        input.key = FourCharCode(fromString: value.pointee.key)
        input.data8 = SMCKeys.readKeyInfo.rawValue
        
        result = call(SMCKeys.kernelIndex.rawValue, input: &input, output: &output)
        if result != kIOReturnSuccess {
            return result
        }
        
        value.pointee.dataSize = UInt32(output.keyInfo.dataSize)
        value.pointee.dataType = output.keyInfo.dataType.toString()
        input.keyInfo.dataSize = output.keyInfo.dataSize
        input.data8 = SMCKeys.readBytes.rawValue
        
        result = call(SMCKeys.kernelIndex.rawValue, input: &input, output: &output)
        if result != kIOReturnSuccess {
            return result
        }
        
        memcpy(&value.pointee.bytes, &output.bytes, Int(value.pointee.dataSize))
        
        return kIOReturnSuccess
    }
    
    private func write(_ value: SMCValModel) -> kern_return_t {
        var input = SMCKeyDataModel()
        var output = SMCKeyDataModel()
        
        input.key = FourCharCode(fromString: value.key)
        input.data8 = SMCKeys.writeBytes.rawValue
        input.keyInfo.dataSize = IOByteCount32(value.dataSize)
        input.bytes = (value.bytes[0], value.bytes[1], value.bytes[2], value.bytes[3], value.bytes[4], value.bytes[5],
                       value.bytes[6], value.bytes[7], value.bytes[8], value.bytes[9], value.bytes[10], value.bytes[11],
                       value.bytes[12], value.bytes[13], value.bytes[14], value.bytes[15], value.bytes[16], value.bytes[17],
                       value.bytes[18], value.bytes[19], value.bytes[20], value.bytes[21], value.bytes[22], value.bytes[23],
                       value.bytes[24], value.bytes[25], value.bytes[26], value.bytes[27], value.bytes[28], value.bytes[29],
                       value.bytes[30], value.bytes[31])
        
        let result = self.call(SMCKeys.kernelIndex.rawValue, input: &input, output: &output)
        if result != kIOReturnSuccess {
            return result
        }
        
        return kIOReturnSuccess
    }
    
    private func call(_ index: UInt8, input: inout SMCKeyDataModel, output: inout SMCKeyDataModel) -> kern_return_t {
        let inputSize = MemoryLayout<SMCKeyDataModel>.stride
        var outputSize = MemoryLayout<SMCKeyDataModel>.stride
        
        return IOConnectCallStructMethod(conn, UInt32(index), &input, inputSize, &output, &outputSize)
    }
}


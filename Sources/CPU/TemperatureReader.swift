//
//  TemperatureReader.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import SystemKit
import SMC

public class TemperatureReader: Reader<Double> {
    var list: [String] = []
    
    public override func setup() {
        switch SystemKit.shared.device.platform {
        case .m1, .m1Pro, .m1Max, .m1Ultra:
            self.list = ["Tp09", "Tp0T", "Tp01", "Tp05", "Tp0D", "Tp0H", "Tp0L", "Tp0P", "Tp0X", "Tp0b"]
        case .m2, .m2Pro, .m2Max, .m2Ultra:
        self.list = ["Tp1h", "Tp1t", "Tp1p", "Tp1l", "Tp01", "Tp05", "Tp09", "Tp0D", "Tp0X", "Tp0b", "Tp0f", "Tp0j"]
        case .m3, .m3Pro, .m3Max, .m3Ultra:
            self.list = ["Te05", "Te0L", "Te0P", "Te0S", "Tf04", "Tf09", "Tf0A", "Tf0B", "Tf0D", "Tf0E", "Tf44", "Tf49", "Tf4A", "Tf4B", "Tf4D", "Tf4E"]
        default: break
        }
    }
    
    public override func read() {
        var temperature: Double? = nil
        
        if let value = SMC.shared.getValue("TC0D"), value < 110 {
            temperature = value
        } else if let value = SMC.shared.getValue("TC0E"), value < 110 {
            temperature = value
        } else if let value = SMC.shared.getValue("TC0F"), value < 110 {
            temperature = value
        } else if let value = SMC.shared.getValue("TC0P"), value < 110 {
            temperature = value
        } else if let value = SMC.shared.getValue("TC0H"), value < 110 {
            temperature = value
        } else {
            var total: Double = 0
            var counter: Double = 0
            self.list.forEach { (key: String) in
                if let value = SMC.shared.getValue(key) {
                    total += value
                    counter += 1
                }
            }
            if total != 0 && counter != 0 {
                temperature = total / counter
            }
        }
        
        self.callback(temperature)
    }
}

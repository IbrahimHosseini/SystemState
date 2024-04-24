//
//  Sensors.swift
//
//
//  Created by Ibrahim on 3/18/24.
//

#if os(macOS)
import AppKit
#endif
import SystemKit
import Module
import SMC
import Common

/// A mudule that get a **Sensors** informations.
///
///  This informations include the ``temprator(_:)`` .
///
public class Sensors: Module {
    private var sensorsReader: SensorsReader?
    
    private var fanValueState: FanValue {
        .percentage
    }
    
    private var temperatures = [SensorService]()
    private var voltages = [SensorService]()
    
    // MARK: - public functions
    
    public override init() {
        super.init()
        
        self.sensorsReader = SensorsReader { [weak self] value in
            self?.usageCallback(value)
        }
        
        self.sensorsReader?.read()
        
        self.sensorsReader?.setInterval(1)
        
        self.setReaders([self.sensorsReader])
    }
    
    /// Disk temperature sensor
    /// - Returns: a number shown the temperature, and a string that shown the temperature in user friendly format
    public func getStorageTemperature() -> (Double, String) {
        let value = temperatures.filter { $0.group == .system && $0.name.hasPrefix("Disk") }.first?.value ?? 0
        return (
         value,
         temperature(value)
        )
    }
    
    /// Network temperature sensor
    /// - Returns: a number shown the temperature, and a string that shown the temperature in user friendly format
    public func getNetworkTemperature() -> (Double, String) {
        let value = temperatures.filter { $0.group == .system && $0.name.hasPrefix("Airport") }.first?.value ?? 0
        return (
         value,
         temperature(value)
        )
    }
    
    /// Battery temperature sensor
    /// - Returns: a number shown the temperature, and a string that shown the temperature in user friendly format
    public func getBatteryTemperature() -> (Double, String) {
        let battery = temperatures.filter { $0.group == .system && $0.name.hasPrefix("Battery") }
        
        let sum = battery.map { $0.value }.reduce(0, { $0 + $1 })
            
        let value = sum/Double(battery.count)
        
        return (
         value,
         temperature(value)
        )
    }
    
    /// System temperature sensor
    /// - Returns: a number shown the temperature, and a string that shown the temperature in user friendly format
    public func getSystemTemperature() -> (Double, String) {
        let value = temperatures.filter { $0.group == .system && $0.name.hasPrefix("NAND") }.first?.value ?? 0
        
        return (
         value,
         temperature(value)
        )
    }
    
    // MARK: - private functions
    
    private func setTemperatures(_ value: [SensorService]) {
        temperatures = value
    }
    
    private func setVoltages(_ value: [SensorService]) {
        voltages = value
    }
    
    private func usageCallback(_ value: SensorsListService?) {
        guard let value else { return }
        
        setTemperatures(value.sensors.filter { $0.type == .temperature })
        
        setVoltages(value.sensors.filter { $0.type == .voltage })
    }
}

public enum FanValue {
    case rpm
    case percentage
}

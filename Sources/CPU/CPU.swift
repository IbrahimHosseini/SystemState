//
//  CPU.swift
//
//
//  Created by Ibrahim on 3/13/24.
//

import SystemKit
import Module
import Foundation

// MARK: - CPU Info

/// A module that get a **CPU** informations.
///
///  This informations include the ``cpuLoad`` and ``topProcess``.
///
public class CPU: Module {
    private var loadReader: LoadReader? = nil
    private var processReader: ProcessReader? = nil
    private var temperatureReader: TemperatureReader? = nil
    private var frequencyReader: FrequencyReader? = nil
    private var limitReader: LimitReader? = nil
    private var averageReader: AverageReader? = nil
        
    private var cpuLoad: CPULoad!
    private var topProcess = [TopProcess]()
    private var _temperature: Double = 0
    
    // MARK: - public functions
    
    public override init() {
        super.init()
        
        self.available = true
        
        // load data
        self.loadReader = LoadReader(.CPU) { [weak self] value in
            self?.loadCallback(value)
        }
        
        self.processReader = ProcessReader(.CPU) { [weak self] value in
            self?.process(value)
        }
        
        self.temperatureReader = TemperatureReader(.CPU) { [weak self] value in
            self?.temperatureCallback(value)
        }
        
        self.loadReader?.read()
        self.loadReader?.setInterval(1)
        
        self.processReader?.read()
        self.processReader?.setInterval(1)
        
        self.temperatureReader?.read()
        self.temperatureReader?.setInterval(1)
        
        self.setReaders([
            self.loadReader,
            self.processReader,
            self.temperatureReader,
            self.frequencyReader,
            self.limitReader,
            self.averageReader
        ])
    }
    
    /// Get CPU information
    /// - Returns: an object that include the ``CPULoad`` data
    public func getCPULoad() -> CPULoad { cpuLoad }
    
    /// Get top CPU process
    /// - Returns: a list of applications that have most used from CPU
    public func getTopProcess() -> [TopProcess] { topProcess }
    
    /// Get the CPU temperature
    /// - Returns: a number that shown temperature and a string that shown readable string
    ///     ``Double`` -> 23.0000
    ///     ``String`` ==> 23 ℃
    public func getTemperature() -> (Double, String) { (_temperature, getReadableTemperature()) }
    
    /// Get the CPU temperature
    /// - Returns: a string that readable by user
    public func getReadableTemperature() -> String { temperature(_temperature) }
    
    // MARK: - private functions
    
    private func setTemperature(_ value: Double) { _temperature = value }
    
    private func setTopProcess(_ value: [TopProcess]) { topProcess = value }
    
    private func setCPULoad(_ value: CPULoad) { cpuLoad = value }
    
    private func loadCallback(_ value: CPULoad?) {
        guard let value else { return }
        
        setCPULoad(value)
    }
    
    private func process(_ lists: [TopProcess]?) {
        guard let lists else { return }
        
        setTopProcess(lists)
    }
    
    private func temperatureCallback(_ value: Double?) {
        guard let value else { return }
        
        setTemperature(value)
    }
}





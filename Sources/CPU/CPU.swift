//
//  CPU.swift
//
//
//  Created by Ibrahim on 3/13/24.
//

import SystemKit
import Module

// MARK: - CPU Info
public class CPU: Module {
    private var loadReader: LoadReader? = nil
    private var processReader: ProcessReader? = nil
    private var temperatureReader: TemperatureReader? = nil
    private var frequencyReader: FrequencyReader? = nil
    private var limitReader: LimitReader? = nil
    private var averageReader: AverageReader? = nil
    
    private var cpuInfo: String = ""
    
    public var cpuLoad: CPULoad!
    public var topProcess = [TopProcess]()
    public var tempreture = ""
    
    
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
    
    private func loadCallback(_ value: CPULoad?) {
        guard let value else { return }
        
        cpuLoad = value
        
        let systemPercent = value.systemLoad.showAsPercent
        let userPercent = value.userLoad.showAsPercent
        let idlePercent = value.idleLoad.showAsPercent
        
        cpuInfo = "system: \(systemPercent), user: \(userPercent), idle: \(idlePercent)"
        print("""
        =====================CPU======================
        \(cpuInfo)
        """)
    }
    
    private func process(_ lists: [TopProcess]?) {
        guard let lists else { return }
        
        topProcess = lists
        
        let mapList = lists.map { $0 }
        
        for i in 0..<mapList.count {
            let process = mapList[i]
            print("""
                    Process list:
                    process\(i) => id: \(process.pid), name: \(process.name), usage: \(process.usage)%
                """)
        }
    }
    
    private func temperatureCallback(_ value: Double?) {
        guard let value else { return }
        print("CPU Tempreture=> \(temperature(value))")
        self.tempreture = temperature(value)
    }
}





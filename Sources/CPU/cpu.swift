//
//  cpu.swift
//
//
//  Created by Ibrahim on 3/13/24.
//

import Foundation
import Kit

// MARK: - CPU Info
public class CPU: Module {
    private var loadReader: LoadReader? = nil
    private var processReader: ProcessReader? = nil
    private var temperatureReader: TemperatureReader? = nil
    private var frequencyReader: FrequencyReader? = nil
    private var limitReader: LimitReader? = nil
    private var averageReader: AverageReader? = nil
    
    public var cpuInfo: String = ""
    
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
    
    private func loadCallback(_ value: CPU_Load?) {
        guard let value else { return }
        let systemPercent = "\(Int(value.systemLoad.rounded(toPlaces: 2) * 100))%"
        let userPercent = "\(Int(value.userLoad.rounded(toPlaces: 2) * 100))%"
        let idlePercent = "\(Int(value.idleLoad.rounded(toPlaces: 2) * 100))%"
        
        cpuInfo = "system: \(systemPercent), user: \(userPercent), idle: \(idlePercent)"
        print("""
        =====================CPU======================
        \(cpuInfo)
        """)
    }
    
    private func process(_ lists: [TopProcess]?) {
        guard let lists else { return }
        
        let mapList = lists.map { $0 }
        
        for i in 0..<mapList.count {
            let process = mapList[i]
            print("""
                    Process list:
                    process\(i) => id: \(process.pid), name: \(process.name), usage: \(process.usage)%
                """)
        }
    }
    
    public func temperatureCallback(_ value: Double?) {
        guard let value else { return }
        print("CPU Tempreture=> \(temperature(value))")
    }
}





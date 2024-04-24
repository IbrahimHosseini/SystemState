//
//  Memory.swift
//
//
//  Created by Ibrahim on 3/13/24.
//

import Foundation
import SystemKit
import Module

/// A mudule that get a **Memory(RAM)** informations.
///
///  This informations include the ``memoryUsage`` and ``topProcess``.
///
public class Memory: Module {
 
    private var usageReader: UsageReader? = nil
    private var processReader: ProcessReader? = nil
    
    private var memoryInfo = ""
    
    public var memoryUsage: MemoryUsage!
    public var topProcess = [TopProcess]()
    
    private var splitValueState: Bool {
        return Store.shared.bool(key: "\(self.config.name)_splitValue", defaultValue: false)
    }
    
    // MARK: - public functions
    
    public override init() {
        
        super.init()
        guard self.available else { return }
        
        self.usageReader?.read()
        
        self.processReader?.read()
        self.usageReader?.setInterval(1)
        
        self.processReader?.setInterval(1)
        
        self.usageReader = UsageReader(.Memory) { [weak self] value in
            self?.loadCallback(value)
        }
        self.processReader = ProcessReader(.Memory) { [weak self] value in
            if let value {
                self?.processCallback(value)
            }
        }
        
        self.processReader?.read()
        
        self.setReaders(
            [
                self.usageReader,
                self.processReader
            ]
        )
    }
    
    private func loadCallback(_ raw: MemoryUsage?) {
        guard let raw else { return }

        memoryUsage = raw
        
        let total: Double = raw.total == 0 ? 1 : raw.total
        let totalSize = total.readableMemory
        let app = raw.app.readableMemory
        let free = raw.free.readableMemory
        let wired = raw.wired.readableMemory
        let compressed = raw.compressed.readableMemory
        let used = raw.used.readableMemory
        
        memoryInfo = "Total: \(totalSize) Used: \(used) App=> \(app), wired: \(wired), compressed: \(compressed), free: \(free)"
        print("""
              ===================MEMORY====================
              \(memoryInfo)
              """)
    }
    
    private func processCallback(_ lists: [TopProcess]?) {
        guard let lists else { return }
        
        self.topProcess = lists
        
        let mapList = lists.map { $0 }
        
        for i in 0..<mapList.count {
            let process = mapList[i]
            print("""
                    +++++ Process list:
                    process\(i) => id: \(process.pid), name: \(process.name), usage: \(process.usage)%
                """)
        }
    }
}

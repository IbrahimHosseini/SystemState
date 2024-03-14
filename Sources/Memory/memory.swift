//
//  memory.swift
//
//
//  Created by Ibrahim on 3/13/24.
//

import Foundation
import Kit

public class Memory: Module {
 
    private var usageReader: UsageReader? = nil
    private var processReader: ProcessReader? = nil
    
    public var memoryInfo = ""
    
    private var splitValueState: Bool {
        return Store.shared.bool(key: "\(self.config.name)_splitValue", defaultValue: false)
    }
    
    public override init() {
        
        super.init()
        guard self.available else { return }
        
        self.usageReader?.read()
        
        self.processReader?.read()
        self.usageReader?.setInterval(1)
        
        self.processReader?.setInterval(1)
        
        self.usageReader = UsageReader(.RAM) { [weak self] value in
            self?.loadCallback(value)
        }
        self.processReader = ProcessReader(.RAM) { [weak self] value in
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
    
    private func loadCallback(_ raw: RAM_Usage?) {
        guard let raw else { return }
        
        let total: Double = raw.total == 0 ? 1 : raw.total
        let totalSize = Units(bytes: Int64(total)).getReadableMemory()
        let app = Units(bytes: Int64(raw.app)).getReadableMemory()
        let free = Units(bytes: Int64(raw.free)).getReadableMemory()
        let wired = Units(bytes: Int64(raw.wired)).getReadableMemory()
        let compressed = Units(bytes: Int64(raw.compressed)).getReadableMemory()
        let used = Units(bytes: Int64(raw.used)).getReadableMemory()
        
        memoryInfo = "memory Total: \(totalSize) Used: \(used) App=> \(app), wired: \(wired), compressed: \(compressed), free: \(free)"
        print("++++ ", memoryInfo)
    }
    
    private func processCallback(_ lists: [TopProcess]?) {
        guard let lists else { return }
        
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

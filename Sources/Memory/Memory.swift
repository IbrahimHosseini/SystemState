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
        
    private var memoryUsage: MemoryUsage?
    private var topProcess = [TopProcess]()
    
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
    
    /// System memory info
    /// - Returns: an object the shown memory information. ``MemoryUsage``
    public func getMemoryUsage() -> MemoryUsage? { memoryUsage }
    
    
    /// Memory top process
    /// - Returns: a list of application that most use the memory. 
    public func getTopProcess() -> [TopProcess] { topProcess }
    
    // MARK: - private functions
    
    private func setMemoryUsage(_ value: MemoryUsage) {
        memoryUsage = value
    }
    
    private func setTopProcess(_ value: [TopProcess]) {
        topProcess = value
    }

    private func loadCallback(_ value: MemoryUsage?) {
        guard let value else { return }

        setMemoryUsage(value)
    }
    
    private func processCallback(_ lists: [TopProcess]?) {
        guard let lists else { return }
        
        setTopProcess(lists)
    }
}

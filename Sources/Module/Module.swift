//
//  Module.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation
import SystemKit

open class Module: ModuleService {
    public var config: ModuleModel
    
    public var available: Bool = false
    
    public var name: String {
        config.name
    }
    public var combinedPosition: Int {
        get {
            Store.shared.int(key: "\(self.name)_position", defaultValue: 0)
        }
        set {
            Store.shared.set(key: "\(self.name)_position", value: newValue)
        }
    }
    
    private let log: NextLog
    private var readers: [ReaderService] = []
    
    private var pauseState: Bool {
        get {
            Store.shared.bool(key: "pause", defaultValue: false)
        }
        set {
            Store.shared.set(key: "pause", value: newValue)
        }
    }
    
    public init() {

        self.config = ModuleModel(in: "")
        
        self.log = NextLog.shared.copy(category: self.config.name)

        self.available = self.isAvailable()
        
        if !self.available {
            debug("Module is not available", log: self.log)
            return
        } else if self.pauseState {
            self.disable()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // load function which call when app start
    public func mount() {
        self.readers.forEach { (reader: ReaderService) in
            reader.initStoreValues(title: self.config.name)
            reader.start()
        }
    }
    
    // disable module
    public func unmount() {
        self.available = false
    }
    
    // terminate function which call before app termination
    public func terminate() {
        self.willTerminate()
        self.readers.forEach{
            $0.stop()
            $0.terminate()
        }
        debug("Module terminated", log: self.log)
    }
    
    // function to call before module terminate
    open func willTerminate() {}
    
    // set module state to enabled
    public func enable() {
        guard self.available else { return }
        
        Store.shared.set(key: "\(self.config.name)_state", value: true)
        self.readers.forEach { (reader: ReaderService) in
            reader.initStoreValues(title: self.config.name)
            reader.start()
        }
    }
    
    // set module state to disabled
    public func disable() {
        guard self.available else { return }
        
        if !self.pauseState { // omit saving the disable state when toggle by pause, need for resume state restoration
            Store.shared.set(key: "\(self.config.name)_state", value: false)
        }
        self.readers.forEach { $0.stop() }
        
        debug("Module disabled", log: self.log)
    }
    
    public func setReaders(_ list: [ReaderService?]) {
        self.readers = list.filter({ $0 != nil }).map({ $0! as ReaderService })
    }
    
    // determine if module is available (can be overrided in module)
    open func isAvailable() -> Bool { return true }
    
    // load the widget and set up. Calls when module init
    private func initWidgets() {
        guard self.available else { return }
    }
    
    // call when popup appear/disappear
    private func visibilityCallback(_ state: Bool) {
        self.readers.filter{ $0.popup }.forEach { (reader: ReaderService) in
            if state {
                reader.unlock()
                reader.start()
            } else {
                reader.pause()
                reader.lock()
            }
        }
    }
}

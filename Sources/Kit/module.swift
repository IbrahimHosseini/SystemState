//
//  module.swift
//
//
//  Created by Ibrahim on 3/11/24.
//


import Cocoa

public protocol Module_p {
    var available: Bool { get }
        
    func mount()
    func unmount()
    
    func terminate()
}

public struct module_c {
    public var name: String = ""
    
    public var defaultState: Bool = false
    
    internal var widgetsConfig: NSDictionary = NSDictionary()
    
    init(in path: String) {
        guard let dict: NSDictionary = NSDictionary(contentsOfFile: path) else { return }
        
        if let name = dict["Name"] as? String {
            self.name = name
        }
        
        if let state = dict["State"] as? Bool {
            self.defaultState = state
        }
    }
}

open class Module: Module_p {
    public var config: module_c
    
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
    private var readers: [Reader_p] = []
    
    private var pauseState: Bool {
        get {
            Store.shared.bool(key: "pause", defaultValue: false)
        }
        set {
            Store.shared.set(key: "pause", value: newValue)
        }
    }
    
    public init() {

        self.config = module_c(in: "")
        
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
        self.readers.forEach { (reader: Reader_p) in
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
        self.readers.forEach { (reader: Reader_p) in
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
    
    public func setReaders(_ list: [Reader_p?]) {
        self.readers = list.filter({ $0 != nil }).map({ $0! as Reader_p })
    }
    
    // determine if module is available (can be overrided in module)
    open func isAvailable() -> Bool { return true }
    
    // load the widget and set up. Calls when module init
    private func initWidgets() {
        guard self.available else { return }
    }
    
    // call when popup appear/disappear
    private func visibilityCallback(_ state: Bool) {
        self.readers.filter{ $0.popup }.forEach { (reader: Reader_p) in
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


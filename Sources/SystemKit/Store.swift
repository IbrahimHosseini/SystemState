//
//  Store.swift
//  
//
//  Created by Ibrahim on 3/11/24.
//


import Cocoa

public class Store {
    public static let shared = Store()
    private let defaults = UserDefaults.standard
    
    public init() {}
    
    public func exist(key: String) -> Bool {
        return self.defaults.object(forKey: key) == nil ? false : true
    }
    
    public func remove(_ key: String) {
        self.defaults.removeObject(forKey: key)
    }
    
    public func bool(key: String, defaultValue value: Bool) -> Bool {
        return !self.exist(key: key) ? value : defaults.bool(forKey: key)
    }
    
    public func string(key: String, defaultValue value: String) -> String {
        return (!self.exist(key: key) ? value : defaults.string(forKey: key))!
    }
    
    public func int(key: String, defaultValue value: Int) -> Int {
        return (!self.exist(key: key) ? value : defaults.integer(forKey: key))
    }
    
    public func data(key: String) -> Data? {
        return defaults.data(forKey: key)
    }
    
    public func set(key: String, value: Bool) {
        self.defaults.set(value, forKey: key)
    }
    
    public func set(key: String, value: String) {
        self.defaults.set(value, forKey: key)
    }
    
    public func set(key: String, value: Int) {
        self.defaults.set(value, forKey: key)
    }
    
    public func set(key: String, value: Data) {
        self.defaults.set(value, forKey: key)
    }
    
    public func reset() {
        self.defaults.dictionaryRepresentation().keys.forEach { key in
            self.defaults.removeObject(forKey: key)
        }
    }
}


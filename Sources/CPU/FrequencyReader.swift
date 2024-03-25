//
//  FrequencyReader.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import SystemKit
import AppKit

internal class FrequencyReader: Reader<Double> {
    private typealias PGSample = UInt64
    private typealias UDouble = UnsafeMutablePointer<Double>
    
    private typealias PG_InitializePointerFunction = @convention(c) () -> Bool
    private typealias PG_ShutdownPointerFunction = @convention(c) () -> Bool
    private typealias PG_ReadSamplePointerFunction = @convention(c) (Int, UnsafeMutablePointer<PGSample>) -> Bool
    private typealias PGSample_GetIAFrequencyPointerFunction = @convention(c) (PGSample, PGSample, UDouble, UDouble, UDouble) -> Bool
    private typealias PGSample_ReleasePointerFunction = @convention(c) (PGSample) -> Bool
    
    private var bundle: CFBundle? = nil
    
    private var pgIntialize: PG_InitializePointerFunction? = nil
    private var pgShutdown: PG_ShutdownPointerFunction? = nil
    private var pgReadSample: PG_ReadSamplePointerFunction? = nil
    private var pgSampleGetIAFrequency: PGSample_GetIAFrequencyPointerFunction? = nil
    private var pgSampleRelease: PGSample_ReleasePointerFunction? = nil
    
    private var sample: PGSample = 0
    private var reconnectAttempt: Int = 0
    
    private var isEnabled: Bool {
        get {
            return Store.shared.bool(key: "CPU_IPG", defaultValue: false)
        }
    }
    
    public override func setup() {
        guard self.isEnabled else { return }
        
        let path: CFString = "/Library/Frameworks/IntelPowerGadget.framework" as CFString
        let bundleURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, path, CFURLPathStyle.cfurlposixPathStyle, true)
        
        self.bundle = CFBundleCreate(kCFAllocatorDefault, bundleURL)
        if self.bundle == nil {
            error("IntelPowerGadget framework not found", log: self.log)
            return
        }
        
        if !CFBundleLoadExecutable(self.bundle) {
            error("failed to load IPG framework", log: self.log)
            return
        }
        
        guard let pgIntialize = CFBundleGetFunctionPointerForName(self.bundle, "PG_Initialize" as CFString) else {
            error("failed to find PG_Initialize", log: self.log)
            return
        }
        guard let pgShutdown = CFBundleGetFunctionPointerForName(self.bundle, "PG_Shutdown" as CFString) else {
            error("failed to find PG_Shutdown", log: self.log)
            return
        }
        guard let pgReadSample = CFBundleGetFunctionPointerForName(self.bundle, "PG_ReadSample" as CFString) else {
            error("failed to find PG_ReadSample", log: self.log)
            return
        }
        guard let pgSampleGetIAFrequency = CFBundleGetFunctionPointerForName(self.bundle, "PGSample_GetIAFrequency" as CFString) else {
            error("failed to find PGSample_GetIAFrequency", log: self.log)
            return
        }
        guard let pgSampleRelease = CFBundleGetFunctionPointerForName(self.bundle, "PGSample_Release" as CFString) else {
            error("failed to find PGSample_Release", log: self.log)
            return
        }
        
        self.pgIntialize = unsafeBitCast(pgIntialize, to: PG_InitializePointerFunction.self)
        self.pgShutdown = unsafeBitCast(pgShutdown, to: PG_ShutdownPointerFunction.self)
        self.pgReadSample = unsafeBitCast(pgReadSample, to: PG_ReadSamplePointerFunction.self)
        self.pgSampleGetIAFrequency = unsafeBitCast(pgSampleGetIAFrequency, to: PGSample_GetIAFrequencyPointerFunction.self)
        self.pgSampleRelease = unsafeBitCast(pgSampleRelease, to: PGSample_ReleasePointerFunction.self)
        
        if let initialize = self.pgIntialize {
            if !initialize() {
                error("IPG initialization failed", log: self.log)
                return
            }
        }
    }
    
    deinit {
        if let bundle = self.bundle {
            CFBundleUnloadExecutable(bundle)
        }
    }
    
    public override func terminate() {
        if let shutdown = self.pgShutdown {
            if !shutdown() {
                error("IPG shutdown failed", log: self.log)
                return
            }
        }
        
        if let release = self.pgSampleRelease {
            if self.sample != 0 {
                _ = release(self.sample)
                return
            }
        }
    }
    
    private func reconnect() {
        if self.reconnectAttempt >= 5 {
            return
        }
        
        self.sample = 0
        self.terminate()
        if let initialize = self.pgIntialize {
            if !initialize() {
                error("IPG initialization failed", log: self.log)
                return
            }
        }
        
        self.reconnectAttempt += 1
    }
    
    public override func read() {
        if !self.isEnabled || self.pgReadSample == nil || self.pgSampleGetIAFrequency == nil || self.pgSampleRelease == nil {
            return
        }
        
        // first sample initlialization
        if self.sample == 0 {
            if !self.pgReadSample!(0, &self.sample) {
                error("read self.sample failed", log: self.log)
            }
            return
        }
        
        var local: PGSample = 0
        var value: Double = 0
        var min: Double = 0
        var max: Double = 0
        
        if !self.pgReadSample!(0, &local) {
            self.reconnect()
            error("read local sample failed", log: self.log)
            return
        }
        
        defer {
            if !self.pgSampleRelease!(self.sample) {
                error("release self.sample failed", log: self.log)
            }
            self.sample = local
        }
        
        if !self.pgSampleGetIAFrequency!(self.sample, local, &value, &min, &max) {
            error("read frequency failed", log: self.log)
            return
        }
        
        self.callback(value)
    }
}

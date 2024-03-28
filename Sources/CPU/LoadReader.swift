//
//  LoadReader.swift
//
//
//  Created by Ibrahim on 3/12/24.
//

#if os(macOS)
import AppKit
#endif
import SystemKit
import SMC

internal class LoadReader: Reader<CPULoad> {
    private var cpuInfo: processor_info_array_t!
    private var prevCpuInfo: processor_info_array_t?
    private var numCpuInfo: mach_msg_type_number_t = 0
    private var numPrevCpuInfo: mach_msg_type_number_t = 0
    private var numCPUs: uint = 0
    private let CPUUsageLock: NSLock = NSLock()
    private var previousInfo = host_cpu_load_info()
    private var hasHyperthreadingCores = false
    
    private var response: CPULoad = CPULoad()
    private var numCPUsU: natural_t = 0
    private var usagePerCore: [Double] = []
    private var cores: [CoreModel]? = nil
    
    public override func setup() {
        self.hasHyperthreadingCores = sysctlByName("hw.physicalcpu") != sysctlByName("hw.logicalcpu")
        [CTL_HW, HW_NCPU].withUnsafeBufferPointer { mib in
            var sizeOfNumCPUs: size_t = MemoryLayout<uint>.size
            let status = sysctl(processor_info_array_t(mutating: mib.baseAddress), 2, &numCPUs, &sizeOfNumCPUs, nil, 0)
            if status != 0 {
                self.numCPUs = 1
            }
        }
        self.cores = SystemKit.shared.device.info.cpu?.cores
    }
    
    public override func read() {
        let result: kern_return_t = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &self.numCPUsU, &self.cpuInfo, &self.numCpuInfo)
        if result == KERN_SUCCESS {
            self.CPUUsageLock.lock()
            self.usagePerCore = []
            
            for i in 0 ..< Int32(numCPUs) {
                var inUse: Int32
                var total: Int32
                if let prevCpuInfo = self.prevCpuInfo {
                    inUse = self.cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_USER)]
                        - prevCpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_USER)]
                        + self.cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_SYSTEM)]
                        - prevCpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_SYSTEM)]
                        + self.cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_NICE)]
                        - prevCpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_NICE)]
                    total = inUse + (self.cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_IDLE)]
                        - prevCpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_IDLE)])
                } else {
                    inUse = self.cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_USER)]
                        + self.cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_SYSTEM)]
                        + self.cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_NICE)]
                    total = inUse + self.cpuInfo[Int(CPU_STATE_MAX * i + CPU_STATE_IDLE)]
                }
                
                if total != 0 {
                    self.usagePerCore.append(Double(inUse) / Double(total))
                }
            }
            self.CPUUsageLock.unlock()
            
            let showHyperthratedCores = Store.shared.bool(key: "CPU_hyperhreading", defaultValue: false)
            if showHyperthratedCores || !self.hasHyperthreadingCores {
                self.response.usagePerCore = self.usagePerCore
            } else {
                var i = 0
                var a = 0
                
                self.response.usagePerCore = []
                while i < Int(self.usagePerCore.count/2) {
                    a = i*2
                    if self.usagePerCore.indices.contains(a) && self.usagePerCore.indices.contains(a+1) {
                        self.response.usagePerCore.append((Double(self.usagePerCore[a]) + Double(self.usagePerCore[a+1])) / 2)
                    }
                    i += 1
                }
            }
            
            if let prevCpuInfo = self.prevCpuInfo {
                let prevCpuInfoSize: size_t = MemoryLayout<integer_t>.stride * Int(self.numPrevCpuInfo)
                vm_deallocate(mach_task_self_, vm_address_t(bitPattern: prevCpuInfo), vm_size_t(prevCpuInfoSize))
            }
            
            self.prevCpuInfo = self.cpuInfo
            self.numPrevCpuInfo = self.numCpuInfo
            
            self.cpuInfo = nil
            self.numCpuInfo = 0
        } else {
            error("host_processor_info(): \(String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error")", log: self.log)
        }
        
        let cpuInfo = hostCPULoadInfo()
        if cpuInfo == nil {
            self.callback(nil)
            return
        }
        
        let userDiff = Double(cpuInfo!.cpu_ticks.0 - self.previousInfo.cpu_ticks.0)
        let sysDiff  = Double(cpuInfo!.cpu_ticks.1 - self.previousInfo.cpu_ticks.1)
        let idleDiff = Double(cpuInfo!.cpu_ticks.2 - self.previousInfo.cpu_ticks.2)
        let niceDiff = Double(cpuInfo!.cpu_ticks.3 - self.previousInfo.cpu_ticks.3)
        let totalTicks = sysDiff + userDiff + niceDiff + idleDiff
        
        let system = sysDiff  / totalTicks
        let user = userDiff  / totalTicks
        let idle = idleDiff  / totalTicks
        
        if !system.isNaN {
            self.response.systemLoad  = system
        }
        if !user.isNaN {
            self.response.userLoad = user
        }
        if !idle.isNaN {
            self.response.idleLoad = idle
        }
        self.previousInfo = cpuInfo!
        self.response.totalUsage = self.response.systemLoad + self.response.userLoad
        
        if let cores = self.cores {
            let eCoresList: [Double] = cores.filter({ $0.type == .efficiency }).compactMap { (c: CoreModel) in
                if self.response.usagePerCore.indices.contains(Int(c.id)) {
                    return self.response.usagePerCore[Int(c.id)]
                }
                return 0
            }
            let pCoresList: [Double] = cores.filter({ $0.type == .performance }).compactMap { (c: CoreModel) in
                if self.response.usagePerCore.indices.contains(Int(c.id)) {
                    return self.response.usagePerCore[Int(c.id)]
                }
                return 0
            }
            
            self.response.usageECores = eCoresList.reduce(0, +)/Double(eCoresList.count)
            self.response.usagePCores = pCoresList.reduce(0, +)/Double(pCoresList.count)
        }
        
        self.callback(self.response)
    }
    
    private func hostCPULoadInfo() -> host_cpu_load_info? {
        let count = MemoryLayout<host_cpu_load_info>.stride/MemoryLayout<integer_t>.stride
        var size = mach_msg_type_number_t(count)
        var cpuLoadInfo = host_cpu_load_info()
        
        let result: kern_return_t = withUnsafeMutablePointer(to: &cpuLoadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: count) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }
        if result != KERN_SUCCESS {
            error("kern_result_t: \(result)", log: self.log)
            return nil
        }
        
        return cpuLoadInfo
    }
}

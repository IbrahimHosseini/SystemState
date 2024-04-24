//
//  Battery.swift
//
//
//  Created by Ibrahim on 3/14/24.
//

#if os(macOS)
import AppKit
#endif
import SystemKit
import Module

/// A module that get a **Battery** informations.
///
/// This informations include the ``batteryInfo`` and ``topProcess``.
///
/// ***Battery Info:** show the battery informations.*
///
///     - level: show an percentage of battery.
///     - cycles: shown an integer as count of cycle.
///     - health: shown an integer number as battery health.
///
/// ***Top Process:** show list of process that currently use the battery.*
///
///     - pid: an id of application.
///     - name: the name of application.
///     - usage: the percentage of usage.
///     - icon: the icon of application
///
///
public class Battery: Module {
    
    private var usageReader: UsageReader? = nil
    private var processReader: ProcessReader? = nil
    
    private var lowLevelNotificationState: Bool = false
    private var highLevelNotificationState: Bool = false
    private var notificationID: String? = nil
    
    /// A model that include the ``BatteryInfoModel/level``, ``BatteryInfoModel/cycles``, and ``BatteryInfoModel/health``.
    private var batteryInfo: BatteryInfoModel!
    
    /// A list of the top process that currently used the  battery.
    private var topProcess = [TopProcess]()
    
    // MARK: - Public functions
    
    public override init() {
        
        super.init()
        guard self.available else { return }
        
        self.usageReader = UsageReader(.battery) { [weak self] value in
            self?.usageCallback(value)
        }
        self.processReader = ProcessReader(.battery) { [weak self] value in
            if let list = value {
                self?.processCallback(list)
            }
        }
        
        self.usageReader?.read()

        self.processReader?.read()
        
        self.setReaders([self.usageReader, self.processReader])
    }
    
    /// A list of the top process that currently used the  battery.
    /// - Returns: a ``TopProcess`` list of applications that have most use from Battery
    public func getTopProcess() -> [TopProcess] { topProcess }
    
    /// Get the battery information
    /// - Returns: a ``BatteryInfoModel`` that include,
    ///   the ``BatteryInfoModel/level``, ``BatteryInfoModel/cycles``, and ``BatteryInfoModel/health``.
    public func getBatteryInfo() -> BatteryInfoModel { batteryInfo }
    
    public override func isAvailable() -> Bool {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        return !sources.isEmpty
    }
    
    // MARK: - Private functions
    
    private func setBatteryInfo(_ value: BatteryUsage) {
        batteryInfo = BatteryInfoModel(
            level: value.level,
            cycles: value.cycles,
            health: value.health,
            isCharging: value.isCharging,
            isBatteryPowered: value.isBatteryPowered,
            temperature: value.temperature
        )
    }
    
    private func setTopProcess(_ value: [TopProcess]) {
        topProcess = value
    }
    
    private func usageCallback(_ value: BatteryUsage?) {
        guard let value else { return }
        
        setBatteryInfo(value)
    }
    
    private func processCallback(_ list: [TopProcess]) {
        setTopProcess(list)
    }

}


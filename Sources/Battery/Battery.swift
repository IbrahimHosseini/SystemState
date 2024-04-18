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

/// A mudule that get a **Battery** informations.
/// 
/// This informations include the ``batteyInfo`` and ``topProcess``.
///
/// ***Battery Info:** show the battery informations.*
///
///     - level: show an percentage of battery.
///     - cycles: shown an interger as count of cycle.
///     - health: shown an interger number as battery health.
///
/// ***Top Process:** show list of process that currently use the battery.*
///
///     - pid: an id of application.
///     - name: the name of application.
///     - usage: the percebtage of usage.
///     - icon: the icon of application
///
///
public class Battery: Module {
    
    private var usageReader: UsageReader? = nil
    private var processReader: ProcessReader? = nil
    
    private var lowLevelNotificationState: Bool = false
    private var highLevelNotificationState: Bool = false
    private var notificationID: String? = nil
    
    /// A model that incloude the ``BatteryInfoModel/level``, ``BatteryInfoModel/cycles``, and ``BatteryInfoModel/health``.
    public var batteyInfo: BatteryInfoModel!
    
    /// A list of the top process that currently using battery.
    public var topProcess = [TopProcess]()
    
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
    
    public override func isAvailable() -> Bool {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        return !sources.isEmpty
    }
    
    private func usageCallback(_ value: BatteryUsage?) {
        guard let value else { return }
        
        batteyInfo = BatteryInfoModel(
            level: value.level,
            cycles: value.cycles,
            health: value.health
        )
    }
    
    private func processCallback(_ list: [TopProcess]) {
        self.topProcess = list
    }

}


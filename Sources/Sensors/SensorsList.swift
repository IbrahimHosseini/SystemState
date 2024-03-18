//
//  SensorsList.swift
//
//
//  Created by Ibrahim on 3/18/24.
//

import Foundation

public class SensorsListService: Codable {
    private var queue: DispatchQueue = DispatchQueue(label: "eu.exelban.Stats.Sensors.SynchronizedArray", attributes: .concurrent)
    
    private var list: [SensorService] = []
    public var sensors: [SensorService] {
        get {
            self.queue.sync{ self.list }
        }
        set {
            self.queue.async(flags: .barrier) {
                self.list = newValue
            }
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case sensors
    }
    
    public init() {}
    
    public func encode(to encoder: Encoder) throws {
//        let wrappers = sensors.map { Sensor_w($0) }
        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(wrappers, forKey: .sensors)
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let wrappers = try container.decode([Sensor_w].self, forKey: .sensors)
//        self.sensors = wrappers.map { $0.sensor }
    }
}

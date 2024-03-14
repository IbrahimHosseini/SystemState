//
//  Storages.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation

public class Storages: Codable {
    private var queue: DispatchQueue = DispatchQueue(label: "eu.exelban.Stats.Disk.SynchronizedArray")
    private var _array: [DriveModel] = []
    public var array: [DriveModel] {
        get { self.queue.sync { self._array } }
        set { self.queue.sync { self._array = newValue } }
    }
    
    enum CodingKeys: String, CodingKey {
        case array
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.array = try container.decode(Array<DriveModel>.self, forKey: CodingKeys.array)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(array, forKey: .array)
    }
    
    init() {}
    
    public var count: Int {
        var result = 0
        self.queue.sync { result = self.array.count }
        return result
    }
    
    // swiftlint:disable empty_count
    public var isEmpty: Bool {
        self.count == 0
    }
    // swiftlint:enable empty_count
    
    public func first(where predicate: (DriveModel) -> Bool) -> DriveModel? {
        return self.array.first(where: predicate)
    }
    
    public func index(where predicate: (DriveModel) -> Bool) -> Int? {
        return self.array.firstIndex(where: predicate)
    }
    
    public func map<ElementOfResult>(_ transform: (DriveModel) -> ElementOfResult?) -> [ElementOfResult] {
        return self.array.compactMap(transform)
    }
    
    public func reversed() -> [DriveModel] {
        return self.array.reversed()
    }
    
    func forEach(_ body: (DriveModel) -> Void) {
        self.array.forEach(body)
    }
    
    public func append( _ element: DriveModel) {
        if !self.array.contains(where: {$0.BSDName == element.BSDName}) {
            self.array.append(element)
        }
    }
    
    public func remove(at index: Int) {
        self.array.remove(at: index)
    }
    
    public func sort() {
        self.array.sort{ $1.removable }
    }
    
    func updateFreeSize(_ idx: Int, newValue: Int64) {
        self.array[idx].free = newValue
    }
    
    func updateReadWrite(_ idx: Int, read: Int64, write: Int64) {
        self.array[idx].activity.readBytes = read
        self.array[idx].activity.writeBytes = write
    }
    
    func updateRead(_ idx: Int, newValue: Int64) {
        self.array[idx].activity.read = newValue
    }
    
    func updateWrite(_ idx: Int, newValue: Int64) {
        self.array[idx].activity.write = newValue
    }
    
    func updateSMARTData(_ idx: Int, smart: SmartModel?) {
        self.array[idx].smart = smart
    }
}

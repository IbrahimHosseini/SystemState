//
//  KeyValueHelper.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation

public protocol KeyValueHelper {
    var key: String { get }
    var value: String { get }
    var additional: Any? { get }
}

public struct KeyValueModel: KeyValueHelper, Codable {
    public let key: String
    public let value: String
    public let additional: Any?
    
    private enum CodingKeys: String, CodingKey {
        case key, value
    }
    
    public init(key: String, value: String, additional: Any? = nil) {
        self.key = key
        self.value = value
        self.additional = additional
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try container.decode(String.self, forKey: .key)
        self.value = try container.decode(String.self, forKey: .value)
        self.additional = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(value, forKey: .value)
    }
}

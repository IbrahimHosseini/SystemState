//
//  DeviceInfoModel.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation

public struct DeviceInfoModel {
    public var model: DeviceModel = DeviceModel(
        name: localizedString("Unknown"),
        year: Calendar.current.component(.year, from: Date()),
        type: .unknown
    )
    public var serialNumber: String? = nil
    public var bootDate: Date? = nil
    
    public var os: OSModel? = nil
    public var info: InfoModel = InfoModel()
    public var platform: Platform? = nil
}

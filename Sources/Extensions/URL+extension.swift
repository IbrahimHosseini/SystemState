//
//  URL+extension.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import Foundation

extension URL {
    func checkFileExist() -> Bool {
        return FileManager.default.fileExists(atPath: self.path)
    }
}

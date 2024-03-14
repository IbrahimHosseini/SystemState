//
//  NSColor+extension.swift
//  
//
//  Created by Ibrahim on 3/14/24.
//

import AppKit

public extension NSColor {
    func grayscaled() -> NSColor {
        guard let space = CGColorSpace(name: CGColorSpace.extendedGray),
              let cg = self.cgColor.converted(to: space, intent: .perceptual, options: nil),
              let color = NSColor.init(cgColor: cg) else {
            return self
        }
        return color
    }
}

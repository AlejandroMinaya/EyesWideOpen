//
//  VideoFilters.swift
//  Eyes Wide Open
//
//  Created by Juan Alcántara on 5/19/21.
//

import Cocoa

func inverseBGRA(src_ptr: UnsafeMutableRawBufferPointer, dst_ptr: UnsafeMutableRawPointer) {
    var pixel_pos = 0
    for (index, value) in src_ptr.enumerated() {
        if (pixel_pos == 3) {
            dst_ptr.storeBytes(of: value, toByteOffset: index, as: UInt8.self)
        } else {
            dst_ptr.storeBytes(of: ~value, toByteOffset: index, as: UInt8.self)
        }
        pixel_pos = (pixel_pos + 1) % 4
    }
}

//
//  VideoFilters.swift
//  Eyes Wide Open
//
//  Created by Juan Alcántara on 5/19/21.
//

import Cocoa

func inverseBGRA(src_ptr: UnsafeMutableRawBufferPointer, dst_ptr: UnsafeMutableRawPointer) {
    for (index, value) in src_ptr.enumerated() {
        if (index % 4 == 3) {
            dst_ptr.storeBytes(of: value, toByteOffset: index, as: UInt8.self)
        } else {
            dst_ptr.storeBytes(of: ~value, toByteOffset: index, as: UInt8.self)
        }
    }
}

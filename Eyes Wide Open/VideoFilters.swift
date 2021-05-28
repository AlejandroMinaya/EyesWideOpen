//
//  VideoFilters.swift
//  Eyes Wide Open
//
//  Created by Juan Alcántara on 5/19/21.
//

import Cocoa

func originalBGRA(src_ptr: UnsafeMutableRawBufferPointer, dst_ptr: UnsafeMutableRawPointer) {
    for (index, value) in src_ptr.enumerated() {
        dst_ptr.storeBytes(of: value, toByteOffset: index, as: UInt8.self)
    }
}

func inverseBGRA(src_ptr: UnsafeMutableRawBufferPointer, dst_ptr: UnsafeMutableRawPointer) {
    for (index, value) in src_ptr.enumerated() {
        if (index % 4 == 3) {
            dst_ptr.storeBytes(of: value, toByteOffset: index, as: UInt8.self)
        } else {
            dst_ptr.storeBytes(of: ~value, toByteOffset: index, as: UInt8.self)
        }
    }
}

func redChannelBGRA(src_ptr: UnsafeMutableRawBufferPointer, dst_ptr: UnsafeMutableRawPointer) {
    for (index, value) in src_ptr.enumerated() {
        if (index % 4 == 2) {
            dst_ptr.storeBytes(of: value, toByteOffset: index, as: UInt8.self)
        }
        else if (index % 4 < 3) {
            dst_ptr.storeBytes(of: 0, toByteOffset: index, as: UInt8.self)
        } else {
            dst_ptr.storeBytes(of: value, toByteOffset: index, as: UInt8.self)
        }
    }
}

func greenChannelBGRA(src_ptr: UnsafeMutableRawBufferPointer, dst_ptr: UnsafeMutableRawPointer) {
    for (index, value) in src_ptr.enumerated() {
        if (index % 4 == 1) {
            dst_ptr.storeBytes(of: value, toByteOffset: index, as: UInt8.self)
        }
        else if (index % 4 < 3) {
            dst_ptr.storeBytes(of: 0, toByteOffset: index, as: UInt8.self)
        } else {
            dst_ptr.storeBytes(of: value, toByteOffset: index, as: UInt8.self)
        }
    }
}


func blueChannelBGRA(src_ptr: UnsafeMutableRawBufferPointer, dst_ptr: UnsafeMutableRawPointer) {
    for (index, value) in src_ptr.enumerated() {
        if (index % 4 == 0) {
            dst_ptr.storeBytes(of: value, toByteOffset: index, as: UInt8.self)
        }
        else if (index % 4 < 3) {
            dst_ptr.storeBytes(of: 0, toByteOffset: index, as: UInt8.self)
        } else {
            dst_ptr.storeBytes(of: value, toByteOffset: index, as: UInt8.self)
        }
    }
}


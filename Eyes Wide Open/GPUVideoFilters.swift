//
//  GPUVideoFilters.swift
//  Eyes Wide Open
//
//  Created by Juan Alcántara on 5/19/21.
//

import Cocoa


// MARK: Metal Initialization
private var device = MTLCreateSystemDefaultDevice()
private let THREADS_PER_BLK = device?.maxThreadsPerThreadgroup
private var defaultLibrary = device?.makeDefaultLibrary()
private var error = NSError()

class MetalSIFunction {
    private var _function: MTLFunction?
    private var _pipeline: MTLComputePipelineState?
    
    // METAL MEMORY CONSTANTS
    private var _gridWidth: Int
    private var _gridHeight: Int
    private var _gridDepth: Int
    private var _blockWidth: Int
    private var _blockHeight: Int
    private var _blockDepth: Int
    
    init (
        functionName: String,
        gridWidth: Int = 1,
        gridHeight: Int = 1,
        gridDepth: Int = 1,
        blockWidth: Int = 1,
        blockHeight: Int = 1,
        blockDepth: Int = 1
    ) {
        self._gridWidth = gridWidth
        self._gridHeight = gridHeight
        self._gridDepth = gridDepth
        self._blockWidth = blockWidth
        self._blockHeight = blockHeight
        self._blockDepth = blockDepth
        
        _function = defaultLibrary?.makeFunction(name: functionName)
        do {
            _pipeline = try device?.makeComputePipelineState(function: _function!)
        } catch {
            debugPrint("Couldn't create Metal pipeline")
        }
    }
    
    public func run(
        src_ptr: UnsafeMutableRawPointer,
        src_sz: Int,
        problem_sz: Int
    ) -> UnsafeMutableRawPointer? {
        let commandQueue = device?.makeCommandQueue()
        let commandBuffer = commandQueue?.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
        
        let src = device?.makeBuffer(bytes: src_ptr, length: src_sz, options: .storageModeManaged)
        let dst = device?.makeBuffer(length: src_sz, options: .storageModeManaged)
        let N_ptr = UnsafeMutableRawPointer.allocate(
            byteCount: MemoryLayout<Int>.size,
            alignment: MemoryLayout<Int>.alignment
        )
        N_ptr.storeBytes(of: problem_sz, as: Int.self)
        let N = device?.makeBuffer(
            bytes: N_ptr, length: MemoryLayout<Int>.size, options: .storageModeManaged
        )
        N_ptr.deallocate()
        
        commandEncoder?.setComputePipelineState(self._pipeline!)
        commandEncoder?.setBuffer(src, offset: 0, index: 0)
        commandEncoder?.setBuffer(dst, offset: 0, index: 1)
        commandEncoder?.setBuffer(N, offset: 0, index: 2)
        
        let gridSize = MTLSizeMake(_gridWidth, _gridHeight, _gridDepth)
        let blockSize = MTLSizeMake(_blockWidth, _blockHeight, _blockDepth)
        
        commandEncoder?.dispatchThreads(gridSize, threadsPerThreadgroup: blockSize)
        commandEncoder?.endEncoding()
        
        let blitCommandEncoder = commandBuffer?.makeBlitCommandEncoder()
        blitCommandEncoder?.synchronize(resource: dst!)
        blitCommandEncoder?.endEncoding()
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        return dst?.contents()
    }
}

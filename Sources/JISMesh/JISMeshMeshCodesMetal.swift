//
//  JISMeshMeshCodesMetal.swift
//  JapaneseMesh
//
//  Created by 大場史温 on 2025/09/24.
//

import Foundation
import Metal
import CoreLocation
import MapKit
import simd

struct JISMeshMeshCodesParameter {
    let regionMin: SIMD2<Float>
    let stepSize: SIMD2<Float>
    let gridSize: SIMD2<UInt32>
    let level: Int32
}

struct JISMeshMeshCodesReturn {
    let code: CLong
}


@MainActor
final class JISMeshMeshCodesMetal {
    public static let shared = try! JISMeshMeshCodesMetal()
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let computePipelineState: MTLComputePipelineState
    
    private init() throws {
        guard let device = MTLCreateSystemDefaultDevice() else { throw MetalError.noDevice }
        self.device = device
        
        guard let commandQueue = device.makeCommandQueue() else { throw MetalError.commandQueueFailed }
        self.commandQueue = commandQueue
        
        guard let metalFileURL = Bundle.module.url(forResource: "JISMeshMeshCodes", withExtension: "metal", subdirectory: "Metal") else { throw MetalError.libraryNotFound}
        let metalSource = try String(contentsOf: metalFileURL)
        let library = try device.makeLibrary(source: metalSource, options: nil)
        
        guard let function = library.makeFunction(name: "JISMeshMeshCodes") else { throw MetalError.functionNotFound }
        self.computePipelineState = try device.makeComputePipelineState(function: function)
    }
    
    public func calculateMesh(region: MKCoordinateRegion, level: JISMeshLevel) -> [String] {
        let minLat = region.center.latitude - region.span.latitudeDelta / 2.0
        let maxLat = region.center.latitude + region.span.latitudeDelta / 2.0
        let minLon = region.center.longitude - region.span.longitudeDelta / 2.0
        let maxLon = region.center.longitude + region.span.longitudeDelta / 2.0
        
        let (stepLat, stepLon) = JISMesh.stepSize(for: level)
        
        let startLon = (floor((minLon - 100.0) / stepLon) * stepLon) + 100.0
        let startLat = floor(minLat / stepLat) * stepLat
        
        let gridWidth  = Int(floor((maxLon - startLon) / stepLon)) + 1
        let gridHeight = Int(floor((maxLat - startLat) / stepLat)) + 1
        let totalCells = gridWidth * gridHeight
        
        var input = JISMeshMeshCodesParameter(
            regionMin: SIMD2<Float>(Float(startLat), Float(startLon)),
            stepSize: SIMD2<Float>(Float(stepLat), Float(stepLon)),
            gridSize: SIMD2<UInt32>(UInt32(gridWidth), UInt32(gridHeight)),
            level: Int32(level.rawValue)
        )
        
        let inputBuffer = device.makeBuffer(bytes: &input,
                                            length: MemoryLayout<JISMeshMeshCodesParameter>.stride,
                                            options: [])!
        
        let outputBuffer = device.makeBuffer(length: MemoryLayout<JISMeshMeshCodesReturn>.stride * totalCells, options: [])!
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder() else { return [] }
        
        computeCommandEncoder.setComputePipelineState(computePipelineState)
        computeCommandEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
        computeCommandEncoder.setBuffer(outputBuffer, offset: 0, index: 1)
        
        let w = computePipelineState.threadExecutionWidth
        let h = computePipelineState.maxTotalThreadsPerThreadgroup / w
        let threadsPerGroup = MTLSize(width: w, height: h, depth: 1)
        
        let groupsPerGrid = MTLSize(
            width: (gridWidth + w - 1) / w,
            height: (gridHeight + h - 1) / h,
            depth: 1
        )
        
        computeCommandEncoder.dispatchThreadgroups(groupsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        
        computeCommandEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        let pointer = outputBuffer.contents().bindMemory(to: JISMeshMeshCodesReturn.self, capacity: totalCells)
        let buffer = UnsafeBufferPointer(start: pointer, count: totalCells)
        
        return buffer.map { String($0.code) }
    }
}

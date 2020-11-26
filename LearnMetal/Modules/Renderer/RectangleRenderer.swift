//
//  RectangleRenderer.swift
//  LearnMetal
//
//  Created by 王江 on 2020/11/26.
//

import Foundation
import MetalKit

class RectangleRenderer: Renderer {
    
    /// the render target
    var targetView: MTKView?
    
    private var vertexBuffer: MTLBuffer?
    private var indexBuffer: MTLBuffer?
    
    private var pipelineState: MTLRenderPipelineState?

    init() {
        guard let device = MetalController.shared.device,
              let library = MetalController.shared.library else { return }
        let vertData: [Float] = [
            0.5, -0.5, 0.0,
            -0.5, -0.5, 0,0,
            -0.5, 0.5, 0.0,
            0.5, 0.5, 0.0
        ]
        let indexes: [UInt16] = [
            0, 1, 2,
            2, 3, 0
        ]
        let length = vertData.count * MemoryLayout.size(ofValue: vertData[0])
        vertexBuffer = device.makeBuffer(bytes: vertData, length: length, options: .storageModeShared)
        let indexesLength = indexes.count * MemoryLayout.size(ofValue: indexes[0])
        indexBuffer = device.makeBuffer(bytes: indexes, length: indexesLength, options: .storageModeShared)
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "basic_vertex")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "basic_fragment")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let e {
            print(e)
        }
    }
}

extension RectangleRenderer {
    func render() {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        guard let mtkView = targetView,
              let mtkLayer = mtkView.layer as? CAMetalLayer,
              let drawable = mtkLayer.nextDrawable() else { return }
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)

        guard let cmdQueue = MetalController.shared.commandQueue,
              let cmdBuffer = cmdQueue.makeCommandBuffer(),
              let renderCMDEncoder = cmdBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
              let pplState = pipelineState,
              let vertBuffer = vertexBuffer,
              let idxBuffer = indexBuffer else { return }
        renderCMDEncoder.setRenderPipelineState(pplState)
        renderCMDEncoder.setVertexBuffer(vertBuffer, offset: 0, index: 0)
        renderCMDEncoder.drawIndexedPrimitives(type: .triangle, indexCount: 6, indexType: .uint16, indexBuffer: idxBuffer, indexBufferOffset: 0)
        renderCMDEncoder.endEncoding()
        
        cmdBuffer.present(drawable)
        cmdBuffer.commit()
    }
}

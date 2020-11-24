//
//  TriangleRenderer.swift
//  LearnMetal
//
//  Created by 王江 on 2020/11/23.
//

import Foundation
import MetalKit

class TriangleRenderer {
    
    /// render target view
    var targetView: MTKView?
    
    private var vertexBuffer: MTLBuffer?
    
    private var pipelineState: MTLRenderPipelineState?

    init() {
        guard let device = MetalController.shared.device,
              let library = MetalController.shared.library else { return }
        let vertData: [Float] = [
            0.0, 0.5, 0.0,
            0.5, -0.5, 0.0,
            -0.5, -0.5, 0,0
        ]
        let length = vertData.count * MemoryLayout.size(ofValue: vertData[0])
        vertexBuffer = device.makeBuffer(bytes: vertData, length: length, options: .storageModeShared)
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

extension TriangleRenderer: Renderer {
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
              let vertBuffer = vertexBuffer else { return }
        renderCMDEncoder.setRenderPipelineState(pplState)
        renderCMDEncoder.setVertexBuffer(vertBuffer, offset: 0, index: 0)
        renderCMDEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        renderCMDEncoder.endEncoding()
        
        cmdBuffer.present(drawable)
        cmdBuffer.commit()
    }
}

//
//  CircleRendereer.swift
//  LearnMetal
//
//  Created by JiangWang on 2020/12/23.
//

import MetalKit

class CircleRenderer: Renderer {
    
    var targetView: MTKView?
    
    private var vertBuffer: MTLBuffer?
    
    private var rpls: MTLRenderPipelineState?
    
    init() {
        let device = MetalController.shared.device
        let library = MetalController.shared.library
        // vertexes
        let vertexes: [VertexPoint] = [
            VertexPoint(position: vector_float3(-0.5, 0.5, 0), radius: 100),
            VertexPoint(position: vector_float3(0, 0, 0), radius: 50),
            VertexPoint(position: vector_float3(0.5, -0.5, 0), radius: 50)
        ]
        vertBuffer = device?.makeBuffer(bytes: vertexes, length: MemoryLayout.size(ofValue: vertexes[0]) * vertexes.count, options: .storageModeShared)
        vertBuffer?.label = "Vertex Buffer: 3 vertexes"
        // render pipeline descriptor
        let rpd = MTLRenderPipelineDescriptor()
        rpd.colorAttachments[0].pixelFormat = .bgra8Unorm
        rpd.vertexFunction = library?.makeFunction(name: "single_cricle_point_vertex")
        rpd.fragmentFunction = library?.makeFunction(name: "single_circle_point_fragment")
//        rpd.vertexFunction = library?.makeFunction(name: "single_line_point_vertex")
//        rpd.fragmentFunction = library?.makeFunction(name: "single_line_point_fragment")
        // blending
        rpd.colorAttachments[0].isBlendingEnabled = true
        // rgb
        rpd.colorAttachments[0].rgbBlendOperation = .add
        rpd.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        rpd.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        // alpha
        rpd.colorAttachments[0].alphaBlendOperation = .add
        rpd.colorAttachments[0].sourceAlphaBlendFactor = .one
        rpd.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha;
        do {
            rpls = try device?.makeRenderPipelineState(descriptor: rpd)
        } catch {
            print(error)
        }
    }
}

extension CircleRenderer {
    
    func render() {
        guard let target = targetView,
              let renderPLS = rpls,
              let device = target.device,
              let cmdQueue = device.makeCommandQueue(),
              let cmdBuffer = cmdQueue.makeCommandBuffer() else { return }
        
        guard let rpd = target.currentRenderPassDescriptor,
              let drawable = target.currentDrawable else { return }
        
        rpd.colorAttachments[0].texture = drawable.texture
        rpd.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        rpd.colorAttachments[0].loadAction = .clear
        rpd.colorAttachments[0].storeAction = .store
        
        let circleRenderEncoder = cmdBuffer.makeRenderCommandEncoder(descriptor: rpd)
        circleRenderEncoder?.setRenderPipelineState(renderPLS)
        circleRenderEncoder?.setVertexBuffer(vertBuffer, offset: 0, index: 0)
        var circleUniform = CircleUniform(color: vector_float4(1, 0, 0, 1), diameter: 50)
        let uniformBuffer = device.makeBuffer(bytes: &circleUniform, length: MemoryLayout.size(ofValue: circleUniform), options: .storageModeShared)
        circleRenderEncoder?.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
        circleRenderEncoder?.drawPrimitives(type: .point, vertexStart: 0, vertexCount: 3)
        
        circleRenderEncoder?.endEncoding()
        
        cmdBuffer.present(drawable)
        
        cmdBuffer.commit()
    }
}

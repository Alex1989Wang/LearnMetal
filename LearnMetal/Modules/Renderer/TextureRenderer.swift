//
//  TextureRenderer.swift
//  LearnMetal
//
//  Created by JiangWang on 2020/11/28.
//

import Foundation
import MetalKit

class TextureRenderer: Renderer {
    
    /// target view
    var targetView: MTKView?
    
    /// the texture to render
    private(set) var texture: MTLTexture?
    
    private(set) var vertexBuffer: MTLBuffer?
    
    private(set) var indexBuffer: MTLBuffer?
    
    private(set) var pipelineState: MTLRenderPipelineState?
    
    init?(tartgetView view: MTKView, textureFile filePath:URL) {
        /// texture
        guard let device = MetalController.shared.device,
              let library = MetalController.shared.library else { return nil }
        let textureLoader = MTKTextureLoader(device: device)
        guard let newTexture = try? textureLoader.newTexture(URL: filePath, options: nil) else { return nil }
        texture = newTexture
        /// vertext data
        let vertexTextCoord: [VertexTextureCoord] = [
            VertexTextureCoord(position: vector_float3(0.5, -1, 0), textCoord: vector_float2(1, 1)),
            VertexTextureCoord(position: vector_float3(-0.5, -1, 0), textCoord: vector_float2(0, 1)),
            VertexTextureCoord(position: vector_float3(-0.5, 1, 0), textCoord: vector_float2(0, 0)),
            VertexTextureCoord(position: vector_float3(0.5, 1, 0), textCoord: vector_float2(1, 0)),
        ]
        let vertexIndexes: [UInt16] = [
            0, 1, 2,
            2, 3, 0
        ]
        let vertBufferLength = vertexTextCoord.count * MemoryLayout.size(ofValue: vertexTextCoord[0])
        vertexBuffer = device.makeBuffer(bytes: vertexTextCoord, length: vertBufferLength, options: .storageModeShared)
        let indexBufferLenght = vertexIndexes.count * MemoryLayout.size(ofValue: vertexIndexes[0])
        indexBuffer = device.makeBuffer(bytes: vertexIndexes, length: indexBufferLenght, options: .storageModeShared)
        /// render pipeline state
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "texture_passs_through_fragment")
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "texture_pass_through_vertex")
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            print(error)
        }
    }
    
}

extension TextureRenderer {
    func render() {
        /// render pass descriptor
        guard let renderPassDescriptor = targetView?.currentRenderPassDescriptor,
              let drawable = targetView?.currentDrawable else { return }
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture

        /// comand
        guard let cmdQueue = MetalController.shared.commandQueue,
              let commandBuffer = cmdQueue.makeCommandBuffer(),
              let idxBuffer = indexBuffer,
              let renderPPLState = pipelineState else { return }
        let renderCmd = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderCmd?.setFragmentTexture(texture, index: 0)
        renderCmd?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderCmd?.setRenderPipelineState(renderPPLState)
        renderCmd?.drawIndexedPrimitives(type: .triangle, indexCount: 6, indexType: .uint16, indexBuffer: idxBuffer, indexBufferOffset: 0)
        renderCmd?.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

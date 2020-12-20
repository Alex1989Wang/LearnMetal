//
//  OffscreenTextureRenderer.swift
//  LearnMetal
//
//  Created by JiangWang on 2020/12/8.
//

import MetalKit

class ScribbleTrackRenderer: Renderer {
    
    /// renderer's target view
    var targetView: MTKView?
    
    /// 滑动的points
    private var trackPoints: [CGPoint] = []
    
    /// the offscreen texture to be filled with
//    private var singleTrackTexture: MTLTexture!
    
    private var singleTrackRenderPPLState: MTLRenderPipelineState?
    
    private var trackVertexesBuffer: MTLBuffer?
    private var trackIndexesBuffer: MTLBuffer?
    private var trackUniformBuffer: MTLBuffer?
    
    private var tracksTexture: MTLTexture!
    
    private var rendererPPLState: MTLRenderPipelineState?
    
    private var rendererVertexesBuffer: MTLBuffer?
    private var rendererIndexesBuffer: MTLBuffer?
    
    /// the width || diameter of the track
    private var trackWidth: UInt16 = 10 //10 pt
    
    private var targetViewSize: CGSize = .zero
    
    init?(targetView view: MTKView, targetViewSize size: CGSize, trackDiameter diameter: CGFloat) {
        targetView = view
        targetViewSize = size
        trackWidth = UInt16(diameter)
        
        guard let library = MetalController.shared.library,
              let device = MetalController.shared.device else {
            return nil
        }
        
        // circle vertex
        let trackVertexes: [VertexTextureCoord] = [
            VertexTextureCoord(position: vector_float3(1, -1, 0), textCoord: vector_float2(1, 1)),
            VertexTextureCoord(position: vector_float3(-1, -1, 0), textCoord: vector_float2(0, 1)),
            VertexTextureCoord(position: vector_float3(-1, 1, 0), textCoord: vector_float2(0, 0)),
            VertexTextureCoord(position: vector_float3(1, 1, 0), textCoord: vector_float2(1, 0)),
        ]
        let indexes: [UInt16] = [
            0, 1, 2,
            2, 3, 0
        ]
        trackVertexesBuffer = device.makeBuffer(bytes: trackVertexes, length: trackVertexes.count * MemoryLayout.size(ofValue: trackVertexes[0]), options: .storageModeShared)
        trackIndexesBuffer = device.makeBuffer(bytes: indexes, length: indexes.count * MemoryLayout.size(ofValue: indexes[0]), options: .storageModeShared)
        var uniforms: CircleUniform = CircleUniform(color: vector_float4(1, 0, 0, 1), diameter: trackWidth)
        trackUniformBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout.size(ofValue: uniforms), options: .storageModeShared)

        // offscreen render pipeline state
        let singleTrackRenderPPLDescriptor = MTLRenderPipelineDescriptor()
        singleTrackRenderPPLDescriptor.colorAttachments[0].pixelFormat = .r8Unorm
        singleTrackRenderPPLDescriptor.vertexFunction = library.makeFunction(name: "circle_vertex")
        singleTrackRenderPPLDescriptor.fragmentFunction = library.makeFunction(name: "circle_fragment")
        do {
            singleTrackRenderPPLState = try device.makeRenderPipelineState(descriptor: singleTrackRenderPPLDescriptor)
        } catch {
            print(error)
        }

        // pipeline state render to screen
        let vertexes: [VertexTextureCoord] = [
            VertexTextureCoord(position: vector_float3(1, 1, 0), textCoord: vector_float2(1, 0)),
            VertexTextureCoord(position: vector_float3(1, -1, 0), textCoord: vector_float2(1, 1)),
            VertexTextureCoord(position: vector_float3(-1, -1, 0), textCoord: vector_float2(0, 1)),
            VertexTextureCoord(position: vector_float3(-1, 1, 0), textCoord: vector_float2(0, 0)),
        ]
        rendererVertexesBuffer = device.makeBuffer(bytes: vertexes, length: vertexes.count * MemoryLayout.size(ofValue: vertexes[0]), options: .storageModeShared)
        rendererIndexesBuffer = device.makeBuffer(bytes: indexes, length: indexes.count * MemoryLayout.size(ofValue: indexes[0]), options: .storageModeShared)
        
        let rendererPPLDescriptor = MTLRenderPipelineDescriptor()
        rendererPPLDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        rendererPPLDescriptor.vertexFunction = library.makeFunction(name: "texture_pass_through_vertex")
        rendererPPLDescriptor.fragmentFunction = library.makeFunction(name: "texture_passs_through_fragment")
        do {
            rendererPPLState = try device.makeRenderPipelineState(descriptor: rendererPPLDescriptor)
        } catch {
            print(error)
        }
        
        let tracksTexDesc = MTLTextureDescriptor()
        tracksTexDesc.width = Int(view.bounds.width)
        tracksTexDesc.height = Int(view.bounds.height)
        tracksTexDesc.pixelFormat = .r8Unorm
        tracksTexDesc.usage = [.shaderRead]
        tracksTexDesc.sampleCount = 1
        tracksTexture = device.makeTexture(descriptor: tracksTexDesc)
    }
}

//MARK: - Public
extension ScribbleTrackRenderer {
    func appendInputPoints(_ points: [CGPoint]) {
        trackPoints.append(contentsOf: points)
    }
}

extension ScribbleTrackRenderer {
    func render() {
        guard let cmdQueue = MetalController.shared.commandQueue,
              let mtlView = targetView,
              let device = MetalController.shared.device else { return }
        
        guard trackPoints.count >= 2 else { return }
        
        var minX: Int = LONG_MAX;
        var maxX: Int = 0;
        var minY: Int = LONG_MAX;
        var maxY: Int = 0;
        trackPoints.forEach { (p) in
            minX = min(Int(p.x), minX)
            maxX = max(Int(p.x), maxX)
            minY = min(Int(p.y), minY)
            maxY = max(Int(p.y), maxY)
        }

        // track texture
        let tWidth = Int(trackWidth)
        minX = max(0, minX - tWidth/2)
        minY = max(0, minY - tWidth/2)
        maxX = min(Int(targetViewSize.width), maxX + tWidth/2)
        maxY = min(Int(targetViewSize.height), maxY + tWidth/2)
        let width = maxX - minX
        let height = maxY - minY
        let texDescriptor = MTLTextureDescriptor()
        texDescriptor.width = width
        texDescriptor.height = height
        texDescriptor.sampleCount = 1
        texDescriptor.pixelFormat = .r8Unorm
        texDescriptor.usage = [.shaderRead, .renderTarget]
        let singleTrackTextureOutput = device.makeTexture(descriptor: texDescriptor)
        
        // command buffer
        guard let cmdBuffer = cmdQueue.makeCommandBuffer() else { return }
        
        let trackTextureInput = device.makeTexture(descriptor: texDescriptor)
        // input is the area alreay drawn
        guard let blitEncoder = cmdBuffer.makeBlitCommandEncoder(),
              let iTrackTex = trackTextureInput,
              let tracksTex = tracksTexture else {
            return
        }
        blitEncoder.copy(from: tracksTex, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(Int(minX), Int(minY), 0), sourceSize: MTLSizeMake(width, height, 1), to: iTrackTex, destinationSlice: 0, destinationLevel: 0, destinationOrigin:  MTLOriginMake(0, 0, 0))
        blitEncoder.endEncoding()

        // render cicle to an offscreen texture
        let circleRenderPassDesc = MTLRenderPassDescriptor()
        circleRenderPassDesc.colorAttachments[0].texture = singleTrackTextureOutput
        circleRenderPassDesc.colorAttachments[0].loadAction = .clear
        circleRenderPassDesc.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        circleRenderPassDesc.colorAttachments[0].storeAction = .store
        
        guard let circleEncoder = cmdBuffer.makeRenderCommandEncoder(descriptor: circleRenderPassDesc),
              let trackPPLState = singleTrackRenderPPLState,
              let tIndexesBuffer = trackIndexesBuffer else { return }
        circleEncoder.setVertexBuffer(trackVertexesBuffer, offset: 0, index: 0)
        circleEncoder.setRenderPipelineState(trackPPLState)
        circleEncoder.setFragmentBuffer(trackUniformBuffer, offset: 0, index: 0)
        // points
        let points: [Point] = trackPoints.map { (p) -> Point in
            var point = Point()
            point.x = Float32(p.x - CGFloat(minX))
            point.y = Float32(p.y - CGFloat(minY))
            return point
        }
        let pointsBuffer = device.makeBuffer(bytes: points, length: points.count * MemoryLayout.size(ofValue: points[0]), options: .storageModeShared)
        circleEncoder.setFragmentBuffer(pointsBuffer, offset: 0, index: 1)
        var pCount: UInt8 = UInt8(points.count)
        let countBuffer = device.makeBuffer(bytes: &pCount, length: MemoryLayout.size(ofValue: pCount), options: .storageModeShared)
        circleEncoder.setFragmentBuffer(countBuffer, offset: 0, index: 2)
        // input texture
        circleEncoder.setFragmentTexture(trackTextureInput, index: 0)
        circleEncoder.drawIndexedPrimitives(type: .triangle, indexCount: 6, indexType: .uint16, indexBuffer: tIndexesBuffer, indexBufferOffset: 0)
        circleEncoder.endEncoding()
        
        // keep the last
        if !trackPoints.isEmpty {
            trackPoints.removeFirst(trackPoints.count - 1)
        }
        
        // blit the single track renderred this time on the tracks
        guard let blitEncoder2 = cmdBuffer.makeBlitCommandEncoder(),
              let sTrackTexture = singleTrackTextureOutput else {
            return
        }
        blitEncoder2.copy(from: sTrackTexture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(0, 0, 0), sourceSize: MTLSizeMake(width, height, 1), to: tracksTex, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOriginMake(Int(minX), Int(minY), 0))
        blitEncoder2.endEncoding()

        /// render to screen
        guard let rendererPassDesc = mtlView.currentRenderPassDescriptor,
              let drawable = targetView?.currentDrawable else { return }
        rendererPassDesc.colorAttachments[0].loadAction = .load
        rendererPassDesc.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 0, blue: 0, alpha: 1)
        rendererPassDesc.colorAttachments[0].texture = drawable.texture
        
        guard let rendererEncoder = cmdBuffer.makeRenderCommandEncoder(descriptor: rendererPassDesc),
              let rPPLState = rendererPPLState,
              let rIndexesBuffer = rendererIndexesBuffer else { return }
        rendererEncoder.setVertexBuffer(rendererVertexesBuffer, offset: 0, index: 0)
        rendererEncoder.setRenderPipelineState(rPPLState)
        rendererEncoder.setFragmentTexture(tracksTex, index: 0)
        rendererEncoder.drawIndexedPrimitives(type: .triangle, indexCount: 6, indexType: .uint16, indexBuffer: rIndexesBuffer, indexBufferOffset: 0)
        rendererEncoder.endEncoding()

        cmdBuffer.present(drawable)
        cmdBuffer.commit()
    }
}

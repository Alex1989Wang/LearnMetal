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
    
    private var rendererPPLState: MTLRenderPipelineState?
    
    private var rendererVertexesBuffer: MTLBuffer?
    private var rendererIndexesBuffer: MTLBuffer?
    
    /// the width || diameter of the track
    private var trackWidth: UInt16 = 10 //10 pt
    
    init?(targetView view: MTKView, trackDiameter diameter: CGFloat) {
        targetView = view
        trackWidth = UInt16(diameter)
        
        guard let library = MetalController.shared.library,
              let device = MetalController.shared.device else {
            return nil
        }
        
        // circle vertex
        let trackVertexes: [Vertex] = [
            Vertex(position: vector_float3(1, 1, 0)),
            Vertex(position: vector_float3(1, -1, 0)),
            Vertex(position: vector_float3(-1, -1, 0)),
            Vertex(position: vector_float3(-1, 1, 0)),
        ]
        let indexes: [UInt16] = [
            0, 1, 2,
            2, 3, 0
        ]
        trackVertexesBuffer = device.makeBuffer(bytes: trackVertexes, length: trackVertexes.count * MemoryLayout.size(ofValue: trackVertexes[0]), options: .storageModeShared)
        trackIndexesBuffer = device.makeBuffer(bytes: indexes, length: indexes.count * MemoryLayout.size(ofValue: indexes[0]), options: .storageModeShared)
        var uniforms: CircleUniform = CircleUniform(color: vector_float4(0, 1, 0, 1), diameter: trackWidth)
        trackUniformBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout.size(ofValue: uniforms), options: .storageModeShared)

        // offscreen render pipeline state
        let singleTrackRenderPPLDescriptor = MTLRenderPipelineDescriptor()
        singleTrackRenderPPLDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
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
            VertexTextureCoord(position: vector_float3(-1, 1, 0), textCoord: vector_float2(1, 1)),
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
        
        var minX: CGFloat = CGFloat.greatestFiniteMagnitude;
        var maxX: CGFloat = 0;
        var minY: CGFloat = CGFloat.greatestFiniteMagnitude;
        var maxY: CGFloat = 0;
        trackPoints.forEach { (p) in
            minX = min(p.x, minX)
            maxX = max(p.x, maxX)
            minY = min(p.y, minY)
            maxY = max(p.y, maxY)
        }

        // track texture
        let width = Int(maxX - minX)
        let height = Int(maxY - minY)
        if width <= 0 || height <= 0 { return }
        let texDescriptor = MTLTextureDescriptor()
        texDescriptor.width = width
        texDescriptor.height = height
        texDescriptor.sampleCount = 1
        texDescriptor.pixelFormat = .bgra8Unorm
        texDescriptor.usage = [.shaderRead, .renderTarget]
        let singleTrackTexture = device.makeTexture(descriptor: texDescriptor)

        // render cicle to an offscreen texture
        let circleRenderPassDesc = MTLRenderPassDescriptor()
        circleRenderPassDesc.colorAttachments[0].texture = singleTrackTexture
        circleRenderPassDesc.colorAttachments[0].loadAction = .clear
        circleRenderPassDesc.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        circleRenderPassDesc.colorAttachments[0].storeAction = .store
        
        guard let cmdBuffer = cmdQueue.makeCommandBuffer() else { return }
        guard let circleEncoder = cmdBuffer.makeRenderCommandEncoder(descriptor: circleRenderPassDesc),
              let trackPPLState = singleTrackRenderPPLState,
              let tIndexesBuffer = trackIndexesBuffer else { return }
        circleEncoder.setVertexBuffer(trackVertexesBuffer, offset: 0, index: 0)
        circleEncoder.setRenderPipelineState(trackPPLState)
        circleEncoder.setFragmentBuffer(trackUniformBuffer, offset: 0, index: 0)
        // points
        let points: [Point] = trackPoints.map { (p) -> Point in
            var point = Point()
            point.x = Float(p.x - minX)
            point.y = Float(p.y - minY)
            return point
        }
        let pointsBuffer = device.makeBuffer(bytes: points, length: points.count * MemoryLayout.size(ofValue: points[0]), options: .storageModeShared)
        circleEncoder.setFragmentBuffer(pointsBuffer, offset: 0, index: 1)
        var pCount = points.count
        let countBuffer = device.makeBuffer(bytes: &pCount, length: MemoryLayout.size(ofValue: pCount), options: .storageModeShared)
        circleEncoder.setFragmentBuffer(countBuffer, offset: 0, index: 2)
        circleEncoder.drawIndexedPrimitives(type: .triangle, indexCount: 6, indexType: .uint16, indexBuffer: tIndexesBuffer, indexBufferOffset: 0)
        circleEncoder.endEncoding()
        
        // keep the last
        if !trackPoints.isEmpty {
            trackPoints.removeFirst(trackPoints.count - 1)
        }

        /// render to screen
        guard let rendererPassDesc = mtlView.currentRenderPassDescriptor,
              let drawable = targetView?.currentDrawable else { return }
        rendererPassDesc.colorAttachments[0].loadAction = .clear
        rendererPassDesc.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 0, blue: 0, alpha: 1)
        rendererPassDesc.colorAttachments[0].texture = drawable.texture
        
        guard let rendererEncoder = cmdBuffer.makeRenderCommandEncoder(descriptor: rendererPassDesc),
              let rPPLState = rendererPPLState,
              let rIndexesBuffer = rendererIndexesBuffer else { return }
        rendererEncoder.setVertexBuffer(rendererVertexesBuffer, offset: 0, index: 0)
        rendererEncoder.setRenderPipelineState(rPPLState)
        rendererEncoder.setFragmentTexture(singleTrackTexture, index: 0)
        rendererEncoder.drawIndexedPrimitives(type: .triangle, indexCount: 6, indexType: .uint16, indexBuffer: rIndexesBuffer, indexBufferOffset: 0)
        rendererEncoder.endEncoding()

        cmdBuffer.present(drawable)
        cmdBuffer.commit()
    }
}

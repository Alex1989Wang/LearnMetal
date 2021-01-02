//
//  ScribbleTrackRenderer1.swift
//  LearnMetal
//
//  Created by JiangWang on 2020/12/22.
//

import MetalKit

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}

/// use *LINES* as drawing primitive
class ScribbleTrackRenderer1: BrushRenderer {
    
    /// renderer's target view
    var targetView: MTKView?
    
    /// 滑动的points
    private(set) var trackPoints: [CGPoint] = []
    
    /// the width || diameter of the track
    private(set) var trackWidth: UInt16 = 50 //50 pixel
    
    private(set) var targetViewSize: CGSize = .zero

    private var singleTrackRenderPPLState: MTLRenderPipelineState?
    
    private var trackUniformBuffer: MTLBuffer?
    
    private var tracksTexture: MTLTexture!
    
    private var rendererPPLState: MTLRenderPipelineState?
    
    private var rendererVertexesBuffer: MTLBuffer?
    private var rendererIndexesBuffer: MTLBuffer?
    
    private var captureScope: MTLCaptureScope?
    
    init?(targetView view: MTKView, targetViewSize size: CGSize, trackDiameter diameter: CGFloat) {
        targetView = view
        targetViewSize = size
        trackWidth = UInt16(diameter)
        
        guard let library = MetalController.shared.library,
              let device = MetalController.shared.device else {
            return nil
        }
        
        captureScope = MTLCaptureManager.shared().makeCaptureScope(device: device)
        
        // common indexes
        let indexes: [UInt16] = [
            0, 1, 2,
            2, 3, 0
        ]
        var uniforms: CircleUniform = CircleUniform(color: vector_float4(1, 0, 0, 1), diameter: trackWidth)
        trackUniformBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout.size(ofValue: uniforms), options: .storageModeShared)

        // offscreen render pipeline state
        let singleTrackRenderPPLDescriptor = MTLRenderPipelineDescriptor()
        singleTrackRenderPPLDescriptor.colorAttachments[0].pixelFormat = .r8Unorm
        singleTrackRenderPPLDescriptor.vertexFunction = library.makeFunction(name: "single_cricle_point_vertex")
        singleTrackRenderPPLDescriptor.fragmentFunction = library.makeFunction(name: "single_circle_point_fragment")
        // blending
        singleTrackRenderPPLDescriptor.colorAttachments[0].isBlendingEnabled = true
        // rgb
        singleTrackRenderPPLDescriptor.colorAttachments[0].rgbBlendOperation = .add
        singleTrackRenderPPLDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        singleTrackRenderPPLDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        // alpha
        singleTrackRenderPPLDescriptor.colorAttachments[0].alphaBlendOperation = .add
        singleTrackRenderPPLDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        singleTrackRenderPPLDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha;
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
        let scale = UIScreen.main.scale
        tracksTexDesc.width = Int(targetViewSize.width * scale)
        tracksTexDesc.height = Int(targetViewSize.height * scale)
        tracksTexDesc.pixelFormat = .r8Unorm
        tracksTexDesc.usage = [.shaderRead, .renderTarget]
        tracksTexDesc.sampleCount = 1
        tracksTexture = device.makeTexture(descriptor: tracksTexDesc)
    }
}

//MARK: - Public
extension ScribbleTrackRenderer1 {
    func appendInputPoints(_ points: [CGPoint]) {
        trackPoints.append(contentsOf: points)
    }
}

extension ScribbleTrackRenderer1 {
    func render() {
        guard let cmdQueue = MetalController.shared.commandQueue,
              let mtlView = targetView,
              let device = MetalController.shared.device else { return }
        
        guard trackPoints.count >= 2 else { return }
        
        // render cicle to an offscreen texture
        let circleRenderPassDesc = MTLRenderPassDescriptor()
        circleRenderPassDesc.colorAttachments[0].texture = tracksTexture
        circleRenderPassDesc.colorAttachments[0].loadAction = .clear
        circleRenderPassDesc.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        circleRenderPassDesc.colorAttachments[0].storeAction = .store
        
        captureScope?.label = "Single Circle"
        captureScope?.begin()
        guard let cmdBuffer = cmdQueue.makeCommandBuffer() else { return }
        guard let circleEncoder = cmdBuffer.makeRenderCommandEncoder(descriptor: circleRenderPassDesc),
              let trackPPLState = singleTrackRenderPPLState else { return }
        // points
        var lastPoint: CGPoint? = nil
        var pointPairs: [(CGPoint, CGPoint)] = []
        for p in trackPoints {
            if let lst = lastPoint {
                let pair = (lst, p)
                pointPairs.append(pair)
            }
            lastPoint = p
        }
        var points: [VertexPoint] = []
        for pair in pointPairs {
            let start = pair.0
            let end = pair.1
            let dis = start.distance(to: end)
            let count = Int(ceil(dis / 1.0))
            let xDelta = (end.x - start.x)/CGFloat(count)
            let yDelta = (end.y - start.y)/CGFloat(count)
            for idx in 0...count {
                let x = Float(start.x + CGFloat(idx) * xDelta - targetViewSize.width * 0.5)/Float(targetViewSize.width * 0.5)
                let y = Float(start.y + CGFloat(idx) * yDelta - targetViewSize.height * 0.5)/Float(targetViewSize.height * 0.5) * -1.0
                let point = VertexPoint(position: vector_float3(x, y, 0), radius: Float(trackWidth))
                points.append(point)
            }
            // last point
            let lastVert = VertexPoint(position: vector_float3(Float(end.x), Float(end.y), 0), radius: Float(trackWidth))
            points.append(lastVert)
        }
        let pointsBuffer = device.makeBuffer(bytes: points, length: points.count * MemoryLayout.size(ofValue: points[0]), options: .storageModeShared)
        circleEncoder.setVertexBuffer(pointsBuffer, offset: 0, index: 0)
        circleEncoder.setRenderPipelineState(trackPPLState)
        // uniform
        circleEncoder.setFragmentBuffer(trackUniformBuffer, offset: 0, index: 0)
        // input texture
        circleEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: points.count)
        circleEncoder.label = "Single Track Encoder"
        circleEncoder.endEncoding()
        
        captureScope?.end()
        
        /// render to screen
        guard let tracksTex = tracksTexture else { return }
        guard let rendererPassDesc = mtlView.currentRenderPassDescriptor,
              let drawable = targetView?.currentDrawable else { return }
        /*
         If all the render target pixels are rendered to, choose the DontCare action. There are no costs associated with this action, and texture data is always interpreted as undefined.
         */
        rendererPassDesc.colorAttachments[0].loadAction = .dontCare
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

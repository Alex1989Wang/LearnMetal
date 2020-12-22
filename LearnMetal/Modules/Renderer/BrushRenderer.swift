//
//  BrushRenderer.swift
//  LearnMetal
//
//  Created by JiangWang on 2020/12/22.
//

import MetalKit

protocol BrushRenderer: Renderer {
    
    /// 滑动的points
    var trackPoints: [CGPoint] { get }
    
    /// the width || diameter of the track
    var trackWidth: UInt16 { get }
    
    var targetViewSize: CGSize { get }
    
    /// add points to be renderred
    /// - Parameter points: the points from touches
    func appendInputPoints(_ points: [CGPoint])
}

//
//  Renderer.swift
//  LearnMetal
//
//  Created by 王江 on 2020/11/23.
//

import Foundation
import MetalKit

protocol Renderer {
    
    /// render target view
    var targetView: MTKView? { get set }
    
    /// render 
    func render()
    
}


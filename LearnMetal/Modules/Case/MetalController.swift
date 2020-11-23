//
//  MetalController.swift
//  LearnMetal
//
//  Created by 王江 on 2020/11/23.
//

import MetalKit

class MetalController {
    
    /// the singleton
    static let shared = MetalController()
    
    /// the device representing gpu
    lazy var device: MTLDevice? = MTLCreateSystemDefaultDevice()
    
    /// the command queue
    lazy var commandQueue: MTLCommandQueue? = {
        return device?.makeCommandQueue()
    }()
    
    //MARK: - init
    init() {
        
    }
}

//MARK: - Public
extension MetalController {
    func render(with renderer: Renderer) {
        renderer.render()
    }
}

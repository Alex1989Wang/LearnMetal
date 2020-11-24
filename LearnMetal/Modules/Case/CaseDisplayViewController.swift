//
//  CaseDisplayViewController.swift
//  LearnMetal
//
//  Created by 王江 on 2020/11/23.
//

import UIKit
import MetalKit

class CaseDisplayViewController: UIViewController {
    
    private var metalView: MTKView!
    
    var renderer: Renderer?
    
    var demoCase: DemoCasesViewController.DemoCases = .triangle
    
    var loop: RenderLooper? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let device = MTLCreateSystemDefaultDevice()
        let frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.width)
        metalView = MTKView(frame: frame, device: device)
        view.addSubview(metalView)
        let constraints = [metalView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                           view.leftAnchor.constraint(equalTo: metalView.leftAnchor),
                           view.rightAnchor.constraint(equalTo: metalView.rightAnchor)]
        metalView.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints(constraints)
        metalView.addConstraint(metalView.widthAnchor.constraint(equalTo: metalView.heightAnchor))
        
        // make renderer
        makeRenderer()
        
        // start render
        loop = RenderLooper()
        loop?.loopCallback = { [weak self] in
            self?.render()
        }
        loop?.setupLooper()
    }
    
    deinit {
        loop?.invalidate()
    }
}

private extension CaseDisplayViewController {
    func makeRenderer() {
        switch demoCase {
        case .triangle:
            renderer = TriangleRenderer()
        }
        renderer?.targetView = metalView
    }
    
    func render() {
        renderer?.render()
    }
}

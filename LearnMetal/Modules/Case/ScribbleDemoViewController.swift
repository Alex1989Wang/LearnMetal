//
//  ScribleDemoViewController.swift
//  LearnMetal
//
//  Created by JiangWang on 2020/12/8.
//

import MetalKit

class ScribbleDemoViewController: UIViewController {

    private var metalView: MTKView!
    
    var renderer: ScribbleTrackRenderer?
    
    var loop: RenderLoop? = nil

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
        
        // pan gesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        metalView.addGestureRecognizer(panGesture)
        
        // make renderer
        makeRenderer()
        
        // start render
        loop = RenderLoop()
        loop?.loopCallback = { [weak self] in
            self?.render()
        }
        loop?.setupLooper()
    }
    
    deinit {
        loop?.invalidate()
    }
}

private extension ScribbleDemoViewController {
    func makeRenderer() {
        renderer = ScribbleTrackRenderer(targetView: self.metalView, trackDiameter: 50)
        renderer?.targetView = self.metalView
    }
    
    func render() {
        renderer?.render()
    }
}

private extension ScribbleDemoViewController {
    @objc func didPan(_ panGesture: UIPanGestureRecognizer) {
        print(panGesture.location(in: self.metalView))
        switch panGesture.state {
        case .began: fallthrough
        case .changed: fallthrough
        case .cancelled: fallthrough
        case .ended:
            renderer?.appendInputPoints([panGesture.location(in: self.metalView)])
        default:
            break
        }
    }
}

//
//  ScribleDemoViewController.swift
//  LearnMetal
//
//  Created by JiangWang on 2020/12/8.
//

import MetalKit

class ScribbleDemoViewController: UIViewController {
    
    private enum ScribbleType {
        case circleTexture
        case primitiveLines
    }

    private var metalView: MTKView!
    
    var renderer: BrushRenderer?
    
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
//        renderer = ScribbleTrackRenderer(targetView: self.metalView, targetViewSize: self.metalView.bounds.size, trackDiameter: 20)
        renderer = ScribbleTrackRenderer1(targetView: self.metalView, targetViewSize: self.metalView.bounds.size, trackDiameter: 20)
        renderer?.targetView = self.metalView
    }
    
    func render() {
        renderer?.render()
    }
}

private extension ScribbleDemoViewController {
    @objc func didPan(_ panGesture: UIPanGestureRecognizer) {
        guard let view = self.metalView else { return }
        print(panGesture.location(in: view))
        switch panGesture.state {
        case .began: fallthrough
        case .changed: fallthrough
        case .cancelled: fallthrough
        case .ended:
            // fix: clamp points into the view
            // blit command will assert (width) and (height)
            var p = panGesture.location(in: view)
            p.x = max(0, min(view.bounds.width, p.x))
            p.y = max(0, min(view.bounds.height, p.y))
            renderer?.appendInputPoints([p])
        default:
            break
        }
    }
}

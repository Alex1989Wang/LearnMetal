//
//  MTKViewModesViewController.swift
//  LearnMetal
//
//  Created by JiangWang on 2020/11/28.
//

import UIKit
import MetalKit

class RenderView: MTKView {
//    override func draw(_ rect: CGRect) {
//        print("RenderView: draw(_ rect:) called")
//        super.draw(rect)
//    }
}

class MTKViewModesViewController: UIViewController {

    private var metalView: RenderView!
    
    var renderer: Renderer?
    
    var mode: DemoCasesViewController.ViewModes = .delegate
    
    var loop: RenderLoop? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let device = MTLCreateSystemDefaultDevice()
        let frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.width)
        metalView = RenderView(frame: frame, device: device)
        view.addSubview(metalView)
        let constraints = [metalView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                           view.leftAnchor.constraint(equalTo: metalView.leftAnchor),
                           view.rightAnchor.constraint(equalTo: metalView.rightAnchor)]
        metalView.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints(constraints)
        metalView.addConstraint(metalView.widthAnchor.constraint(equalTo: metalView.heightAnchor))
        
        // make renderer
        makeRenderer()
        
        // use different render-driven strategies
        initModes()
    }
    
    deinit {
        loop?.invalidate()
    }
}

private extension MTKViewModesViewController {
    
    func initModes() {
        switch mode {
        case .delegate:
            metalView.enableSetNeedsDisplay = false
            metalView?.delegate = self
        case .loopDriven:
            metalView.enableSetNeedsDisplay = false
            loop = RenderLoop()
            loop?.loopCallback = { [weak self] in
                print("View Modes: custom render loop")
                self?.renderer?.render()
            }
            loop?.setupLooper()
        case .needsBased:
            /*
             @discussion If true, then the view behaves similarily to a UIView or NSView, responding to calls to setNeedsDisplay. When the view has been marked for display, the view is automatically redisplayed on each pass through the application’s event loop. Setting enableSetNeedsDisplay to true will also pause the MTKView's internal render loop and updates will instead be event driven. The default value is false.
             */
            metalView.enableSetNeedsDisplay = true
        //            metalView.delegate = self
            loop = RenderLoop()
            loop?.loopCallback = { [weak self] in
                print("View Modes: event-driven render")
                self?.metalView?.setNeedsDisplay()
                // maybe it's better to put renderer into the draw(_ rect:) function
                self?.renderer?.render()
            }
            loop?.setupLooper()
        }
    }

    func makeRenderer() {
        renderer = TriangleRenderer()
        renderer?.targetView = metalView
    }
}

extension MTKViewModesViewController: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        /*
         * frame #0: 0x000000010aa22e68 LearnMetal`MTKViewModesViewController.draw(view=0x00007fe96b709df0, self=0x00007fe96b618680) at MTKViewModesViewController.swift:75:17
           frame #1: 0x000000010aa23014 LearnMetal`@objc MTKViewModesViewController.draw(in:) at <compiler-generated>:0
           frame #2: 0x00007fff3c52aa18 MetalKit`-[MTKView draw] + 185
           frame #3: 0x00007fff3c526cd1 MetalKit`-[MTKViewDisplayLinkTarget draw] + 34
           frame #4: 0x00007fff278e732d QuartzCore`CA::Display::DisplayLink::dispatch_items(unsigned long long, unsigned long long, unsigned long long) + 755
           frame #5: 0x00007fff279cb99c QuartzCore`display_timer_callback(__CFMachPort*, void*, long, void*) + 639
           frame #6: 0x00007fff2037670c CoreFoundation`__CFMachPortPerform + 157
           frame #7: 0x00007fff203a913d CoreFoundation`__CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE1_PERFORM_FUNCTION__ + 41
           frame #8: 0x00007fff203a84de CoreFoundation`__CFRunLoopDoSource1 + 614
           frame #9: 0x00007fff203a29ba CoreFoundation`__CFRunLoopRun + 2353
         */
        print("View Modes: delegate")
        /*
         if draw(_ rect:) is overrided, this delegate function will not be called.
         */
        renderer?.render()
    }
}

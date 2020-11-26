//
//  RenderLooper.swift
//  LearnMetal
//
//  Created by 王江 on 2020/11/24.
//

import UIKit

class RenderLoop {
    
    private var displayLink: CADisplayLink?
    
    var loopCallback:(()->Void)?
}

extension RenderLoop {
    func setupLooper() {
        if let _ = displayLink {
            displayLink?.invalidate()
            displayLink = nil
        }
        displayLink = CADisplayLink(target: self, selector: #selector(fired))
        displayLink?.add(to: RunLoop.main, forMode: .common)
    }
    
    func invalidate() {
        displayLink?.invalidate()
        displayLink = nil
    }
}

private extension RenderLoop {
    @objc func fired() {
        loopCallback?()
    }
}

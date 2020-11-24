//
//  RenderLooper.swift
//  LearnMetal
//
//  Created by 王江 on 2020/11/24.
//

import UIKit

class RenderLooper {
    
    private var displayLink: CADisplayLink?
    
    var loopCallback:(()->Void)?
}

extension RenderLooper {
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

private extension RenderLooper {
    @objc func fired() {
        loopCallback?()
    }
}

//
//  Animator.swift
//  Timer
//
//  Created by Miles Vinson on 2/12/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import UIKit

@objc protocol AnimatorDelegate: class
{
    @objc func animationDidUpdate(phase: CGFloat) //0.0 - 1.0
    @objc optional func animationDidComplete()
}

class Animator
{
    
    private var displayLink: CADisplayLink?
    
    private var startTime = 0.0
    private var duration = 0.0
    
    private var easing: ((Double) -> Double) = Curve.cubic.easeInOut
    private var animationInProgress = false
    
    public var startValue: Any?
    public var endValue: Any?
    
    public var isAnimating: Bool {
        return animationInProgress
    }
    
    weak var delegate: AnimatorDelegate?
    
    init()
    {
        
    }
    
    /**
     Starts the animation from the beginning, stopping any previous animations.
     - Parameter duration: Duration of the animation (in seconds)
     */
    public func startAnimation(duration: TimeInterval, easing: ((Double) -> Double)?)
    {
        stopAnimation()
        self.duration = Double(duration)
        self.startTime = CACurrentMediaTime()
        if let easing = easing {
            self.easing = easing
        }
        
        
        let displayLink = CADisplayLink(
            target: self, selector: #selector(updateAnimation)
        )
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
        
        animationInProgress = true
    }
    
    public func stopAnimation()
    {
        displayLink?.invalidate()
        displayLink = nil
        animationInProgress = false
    }
    
    @objc private func updateAnimation()
    {
        let elapsed = CACurrentMediaTime() - startTime
        
        var phase = CGFloat(easing(elapsed/duration))
        
        if elapsed >= duration
        {
            phase = 1.0
            stopAnimation()
            delegate?.animationDidUpdate(phase: phase)
            delegate?.animationDidComplete?()
        }
        else
        {
            delegate?.animationDidUpdate(phase: phase)
        }
        
        
    }
    
    
}

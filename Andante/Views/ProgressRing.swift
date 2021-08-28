//
//  ProgressRing.swift
//  Andante
//
//  Created by Miles Vinson on 10/14/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class ProgressRing: UIView, AnimatorDelegate {
    
    private let circleBG = CAShapeLayer()
    private let progressRing = CAShapeLayer()
    
    public var lineWidth: CGFloat {
        get {
            return circleBG.lineWidth
        }
        set {
            circleBG.lineWidth = newValue
            progressRing.lineWidth = newValue
            setNeedsLayout()
        }
    }
    
    public var progress: CGFloat = 0
    
    private let animator = Animator()
    
    init() {
        super.init(frame: .zero)
        
        self.layer.addSublayer(circleBG)
        self.layer.addSublayer(progressRing)
        self.backgroundColor = .clear
        
        circleBG.lineWidth = 5
        circleBG.strokeColor = Colors.lightColor.cgColor
        circleBG.fillColor = UIColor.clear.cgColor
        
        progressRing.lineWidth = 5
        progressRing.strokeColor = Colors.orange.cgColor
        progressRing.fillColor = UIColor.clear.cgColor
        progressRing.lineCap = .round
        
        animator.delegate = self
        
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        circleBG.strokeColor = Colors.lightColor.cgColor
        progressRing.strokeColor = Colors.orange.cgColor
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let bgPath = UIBezierPath()
        bgPath.addArc(withCenter: CGPoint(x: self.bounds.midX,
                                          y: self.bounds.midY),
                      radius: self.bounds.width/2,
                      startAngle: 0,
                      endAngle: CGFloat.pi*2,
                      clockwise: true)
        circleBG.path = bgPath.cgPath
        
        
        if animator.isAnimating { return }
        
        layoutShapes(for: min(1, progress))
        
    }
    
    private func layoutShapes(for progress: CGFloat) {
        
        let endAngle = -CGFloat.pi/2 + (progress*CGFloat.pi*2)
        
        let path = UIBezierPath()
        path.addArc(
            withCenter: self.bounds.center,
            radius: self.bounds.width/2,
            startAngle: -CGFloat.pi/2,
            endAngle: endAngle,
            clockwise: true)
        progressRing.path = path.cgPath
        
    }
    
    public func updateProgressWithoutAnimation() {
        layoutShapes(for: progress)
    }
    
    public func animate() {
        animator.startValue = 0
        animator.endValue = min(1, progress)
        
        animator.startAnimation(duration: 0.6, easing: Curve.cubic.easeInOut)
    }
    
    public func animateTo(_ progress: CGFloat) {
        animator.startValue = min(self.progress, 1)
        animator.endValue = min(progress, 1)
        self.progress = progress

        animator.startAnimation(duration: 0.6, easing: Curve.cubic.easeInOut)
    }
    
    func animationDidUpdate(phase: CGFloat) {
        let startValue = animator.startValue as? CGFloat ?? 0
        let endValue = animator.endValue as? CGFloat ?? 0
        
        let progress = startValue + phase * (endValue - startValue)
        layoutShapes(for: progress)
    }
    
}


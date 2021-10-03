//
//  PulltoSettingsView.swift
//  Andante
//
//  Created by Miles on 9/27/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class PullToSettingsView: UIView {
    
    private(set) var progress: CGFloat = 0
    
    private var arrowShape = CAShapeLayer()
    
    private var didReachMaxProgress = false
    private let haptic = UIImpactFeedbackGenerator(style: .light)
    
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        arrowShape.lineWidth = 4
        arrowShape.lineCap = .round
        arrowShape.lineJoin = .round
        arrowShape.strokeColor = Colors.lightText.withAlphaComponent(0.2).cgColor
        arrowShape.fillColor = UIColor.clear.cgColor
        self.layer.addSublayer(arrowShape)
        
        label.text = "Settings"
        label.textColor = Colors.extraLightText
        label.font = Fonts.medium.withSize(14)
        label.alpha = 0
        label.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        //self.addSubview(label)
        
        self.alpha = 0
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        arrowShape.strokeColor = Colors.lightText.withAlphaComponent(0.2).cgColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let center = CGPoint(x: self.bounds.midX, y: self.bounds.maxY - self.bounds.height * 0.1)
        let size = CGSize(width: 30, height: 2 + self.progress * 6)
        
        let leftPt = CGPoint(x: center.x - size.width/2, y: center.y - size.height)
        let rightPt = CGPoint(x: center.x + size.width/2, y: center.y - size.height)
        
        let path = UIBezierPath()
        path.move(to: leftPt)
        path.addLine(to: center)
        path.addLine(to: rightPt)
        
        self.arrowShape.path = path.cgPath
        
        label.sizeToFit()
        label.center = center.offset(dx: 0, dy: -36)
        
    }
    
    public func setProgress(_ progress: CGFloat) {
        self.progress = progress
        
        self.alpha = progress * 2
    
        
        if progress >= 1 {
            if !didReachMaxProgress {
                didReachMaxProgress = true
                haptic.impactOccurred(intensity: 0.75)
                arrowShape.strokeColor = Colors.orange.cgColor
                
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.84, initialSpringVelocity: 2, options: [.beginFromCurrentState, .allowUserInteraction]) {
                    self.label.transform = .identity
                    self.label.alpha = 1
                } completion: { _ in
                    //
                }

                
            }
        } else {
            if didReachMaxProgress {
                didReachMaxProgress = false
                arrowShape.strokeColor = Colors.lightText.withAlphaComponent(0.2).cgColor
                
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.84, initialSpringVelocity: 2, options: [.beginFromCurrentState, .allowUserInteraction]) {
                    self.label.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                    self.label.alpha = 0
                } completion: { _ in
                    //
                }
            }
        }
    }
    
    public func didPullToOpenSettings() {
        
    }
}

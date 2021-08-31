//
//  PullToSettingsView.swift
//  Andante
//
//  Created by Miles on 8/29/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit
import Combine

class PullToSettingsView: UIView {
    
    private let label = UILabel()
    
    private(set) var progress: CGFloat = 0
    
    private let profileIcon = ProfileImageView()
    private let backgroundRing = CAShapeLayer()
    private let animationRing = CAShapeLayer()
    private let backgroundPulse = UIView()
    
    enum State {
        case pulling, readyToRelease
    }
    
    private var state: State = .pulling
    
    private var cancellables = Set<AnyCancellable>()
    public var activeProfile: CDProfile? {
        didSet {
            self.cancellables.removeAll()
            self.activeProfile?.publisher(for: \.iconName).sink(receiveValue: { iconName in
                self.profileIcon.profile = self.activeProfile
            }).store(in: &self.cancellables)
        }
    }
    
    private let haptic = UIImpactFeedbackGenerator(style: .light)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundPulse.alpha = 0
        self.backgroundPulse.backgroundColor = Colors.orange.withAlphaComponent(0.3)
        self.addSubview(backgroundPulse)
        
        self.label.text = "Pull to open Settings"
        self.label.textColor = Colors.text.withAlphaComponent(0.3)
        self.label.font = Fonts.regular.withSize(14)
        self.addSubview(label)
                    
        self.profileIcon.backgroundColor = Colors.backgroundColor
        
        // TODO update on change icon / change active profile
        self.profileIcon.profile = User.getActiveProfile()
        
        self.addSubview(self.profileIcon)
        
        self.backgroundRing.strokeColor = Colors.text.withAlphaComponent(0.1).cgColor
        self.backgroundRing.lineWidth = 3.5
        self.backgroundRing.fillColor = UIColor.clear.cgColor
        self.profileIcon.layer.addSublayer(self.backgroundRing)
        
        self.animationRing.strokeColor = Colors.orange.cgColor
        self.animationRing.lineCap = .round
        self.animationRing.lineWidth = 3.5
        self.animationRing.fillColor = UIColor.clear.cgColor
        self.profileIcon.layer.addSublayer(self.animationRing)
        
        self.setProgress(0)

    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.animationRing.strokeColor = Colors.orange.cgColor
        self.backgroundRing.strokeColor = Colors.text.withAlphaComponent(0.1).cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.sizeToFit()
        self.label.center = self.bounds.center.offset(dx: 0, dy: 20)
        
        self.profileIcon.bounds.size = CGSize(width: 34, height: 34)
        self.profileIcon.center = self.bounds.center.offset(dx: 0, dy: -14)
        
        self.animationRing.frame = self.profileIcon.bounds
        self.backgroundRing.frame = self.backgroundRing.bounds
        self.backgroundRing.path = UIBezierPath(roundedRect: self.profileIcon.bounds, cornerRadius: self.profileIcon.bounds.width / 2).cgPath
        
        self.backgroundPulse.bounds.size = self.profileIcon.bounds.size
        self.backgroundPulse.center = self.profileIcon.center
        self.backgroundPulse.layer.cornerRadius = self.profileIcon.bounds.width / 2
        
    }
    
    private func setArc(for progress: CGFloat) {
        self.animationRing.path = UIBezierPath(
            arcCenter: self.profileIcon.bounds.center,
            radius: self.profileIcon.bounds.width / 2,
            startAngle: -CGFloat.pi/2,
            endAngle: 1.5*CGFloat.pi * progress,
            clockwise: true).cgPath
            
    }
    
    
    private var isPausingAnimation = false
    public func didPullToOpenSettings() {
        // fade away and don't change anything else to keep the animation smooth
        self.isPausingAnimation = true
        
        UIView.animate(withDuration: 0.15) {
            self.alpha = 0
        } completion: { complete in
            self.isPausingAnimation = false
            self.setProgress(self.progress)
            self.alpha = 1
        }

    }
    
    public func setProgress(_ progress: CGFloat) {
        self.progress = progress
        
        guard !self.isPausingAnimation else { return }
                
        if progress > 0.25 {
            let newProgress = (progress - 0.25) / 0.75
            self.label.alpha = newProgress
            self.profileIcon.alpha = newProgress
            self.setArc(for: newProgress)
        }
        else {
            self.label.alpha = 0
            self.profileIcon.alpha = 0
            self.setArc(for: 0)
        }
        
        if progress >= 1 {
            if self.state == .pulling {
                self.state = .readyToRelease
                
                self.haptic.impactOccurred()
                self.label.text = "Release to open Settings"
                
                self.backgroundPulse.alpha = 1
                self.backgroundPulse.transform = .identity
                UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, animations: {
                    self.backgroundPulse.transform = CGAffineTransform(scaleX: 2, y: 2)
                    self.backgroundPulse.alpha = 0
                }, completion: nil)

            }
        }
        else {
            if self.state == .readyToRelease {
                self.state = .pulling
                
                self.label.text = "Pull to open Settings"
                       
                UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [.beginFromCurrentState], animations: {
                    self.backgroundPulse.alpha = 0
                }, completion: nil)
                
            }
        }
        
    }
    
}

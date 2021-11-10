//
//  StreakView.swift
//  Andante
//
//  Created by Miles on 11/9/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit
import Lottie

class StreakView: CustomButton {
    
    private let animationView = AnimationView(name: "flame")
    private let label = UILabel()
    
    public var streak: Int = 0 {
        didSet {
            self.updateUI(lastStreak: oldValue)
        }
    }
    
    public var animationFrame: AnimationFrameTime {
        get { return self.animationView.currentFrame }
        set {
            self.animationView.currentFrame = newValue
            if self.streak > 0 {
                self.animationView.play()
            }
        }
    }
    
    override init() {
        super.init()
        
        self.isUserInteractionEnabled = false
        
        self.animationView.loopMode = .loop
        self.animationView.backgroundBehavior = .pauseAndRestore
        self.addSubview(self.animationView)
        
        self.label.font = Fonts.semibold.withSize(17)
        self.addSubview(self.label)
    }
    
    private func updateUI(lastStreak: Int) {
        label.text = "\(self.streak)"
        label.textColor = self.streak == 0 ? Colors.extraLightText : Colors.text
        
        if self.streak > 0 {
            self.setFlameColor(Colors.orange)
            if self.animationView.isAnimationPlaying == false {
                self.animationView.play()
            }
        } else {
            self.setFlameColor(Colors.extraLightText)
            self.animationView.stop()
        }
        
    }
    
    private func setFlameColor(_ color: UIColor) {
        self.animationView.setValueProvider(
            ColorValueProvider(color.lottieColorValue),
            keypath: AnimationKeypath(keypath: "fire.Shape 1.Fill 1.Color"))
        
        self.animationView.setValueProvider(
            ColorValueProvider(Colors.foregroundColor.lottieColorValue),
            keypath: AnimationKeypath(keypath: "cutout.Group 1.Fill 1.Color"))
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            if self.streak > 0 {
                self.setFlameColor(Colors.orange)
            } else {
                self.setFlameColor(Colors.extraLightText)
            }
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let labelWidth = self.label.sizeThatFits(size).width
        let flameWidth: CGFloat = 30
        return CGSize(width: labelWidth + flameWidth + 2, height: 42)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.animationView.frame = CGRect(
            x: 0, y: self.bounds.midY - 30 / 2,
            width: 30, height: 30).insetBy(dx: -8, dy: -8)
        
        self.label.sizeToFit()
        self.label.frame.origin = CGPoint(
            x: self.bounds.maxX - self.label.bounds.width,
            y: self.bounds.midY - self.label.bounds.height / 2)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}

//
//  HeaderView.swift
//  Andante
//
//  Created by Miles Vinson on 6/21/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit
import Lottie

class HeaderView: UIView {
    
    static var accessoryHeight: CGFloat = 72
    
    /*
     Does not include Safe Area
     */
    public var height: CGFloat = 124
    public var minHeight: CGFloat = 52
    
    private let topView = UIView()
    public let botView = UIView()
    
    private let sep = Separator(position: .bottom)
        
    private let streakView = CustomButton()
    
    private let streakAnimation = AnimationView(name: "flame")
    private let streakLabel = UILabel()
    
    private let profileView = ProfileImagePushButton()
    private let label = UILabel()
    
    public var profileButtonHandler: (()->Void)?
    public var streakViewHandler: (()->Void)?
    
    private var isBotViewFocused = false
    private var isAnimatingFocus = false
        
    public var isSidebarLayout = false {
        didSet {
            setViewsForSizeClass()
        }
    }
    
    public var profile: CDProfile? {
        didSet {
            profileView.profileImg.profile = profile
            reloadStreak()
        }
    }
    
        
    public var title: String? {
        didSet {
            label.text = title
            setNeedsLayout()
        }
    }
    
    private func setFlameColor(_ color: UIColor) {
        color.lottieColorValue
        self.streakAnimation.setValueProvider(
            ColorValueProvider(color.lottieColorValue),
            keypath: AnimationKeypath(keypath: "fire.Shape 1.Fill 1.Color"))
        
        self.streakAnimation.setValueProvider(
            ColorValueProvider(Colors.foregroundColor.lottieColorValue),
            keypath: AnimationKeypath(keypath: "cutout.Group 1.Fill 1.Color"))
    }
    
    private var lastStreak: Int = 0
    
    @objc func reloadStreak() {
        let streak = PracticeDatabase.shared.currentStreak()
        self.lastStreak = streak
        streakLabel.text = "\(streak)"
        streakLabel.textColor = streak == 0 ? Colors.extraLightText : Colors.text
        
        if streak > 0 {
            setFlameColor(Colors.orange)
            if streakAnimation.isAnimationPlaying == false {
                streakAnimation.play()
            }
        } else {
            setFlameColor(Colors.extraLightText)
            streakAnimation.stop()
        }
        
        setNeedsLayout()
    }
    
    public var streakAnimationFrame: AnimationFrameTime {
        get { return self.streakAnimation.currentFrame }
        set {
            self.streakAnimation.currentFrame = newValue
            if lastStreak > 0 {
                self.streakAnimation.play()
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            if lastStreak > 0 {
                setFlameColor(Colors.orange)
            } else {
                setFlameColor(Colors.extraLightText)
            }
        }
    }
    
    init() {
        super.init(frame: .zero)
                
        backgroundColor = Colors.barColor
        
        addSubview(topView)
        
        self.streakAnimation.loopMode = .loop
        self.streakAnimation.backgroundBehavior = .pauseAndRestore
        self.streakView.addSubview(self.streakAnimation)
        
        self.streakLabel.font = Fonts.semibold.withSize(17)
        self.streakView.addSubview(self.streakLabel)
        
        streakView.titleLabel?.font = Fonts.semibold.withSize(17)
        streakView.addTarget(self, action: #selector(didTapStreakView), for: .touchUpInside)
        streakView.highlightAction = { highlighted in
            if highlighted {
                self.streakView.alpha = 0.2
            }
            else {
                UIView.animate(withDuration: 0.2) {
                    self.streakView.alpha = 1
                }
            }
        }
        streakView.isUserInteractionEnabled = false
        topView.addSubview(streakView)
        
        self.reloadStreak()
                
        profileView.action = {
            self.profileButtonHandler?()
        }
        topView.addSubview(profileView)
        
        label.textColor = Colors.text
        
        label.text = "Home"
        topView.addSubview(label)
        
        addSubview(botView)
        addSubview(sep)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadStreak), name: PracticeDatabase.PracticeDatabaseStreakDidChangeNotification, object: nil)
                
    }
    
    func setViewsForSizeClass() {
        if !isSidebarLayout {
            
            profileView.isHidden = false
            streakView.isHidden = false
            label.font = Fonts.bold.withSize(18)
            
            // Handle focus state
            if self.isBotViewFocused {
                self.topView.alpha = 0
            }
            
            height = 124
            minHeight = 52
        }
        else {
            profileView.isHidden = true
            streakView.isHidden = true
            label.font = Fonts.bold.withSize(20)
            
            // Handle focus state
            self.topView.alpha = 1
            
            height = 60
            minHeight = 60
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if isAnimatingFocus { return }
        
        setViewsForSizeClass()
        
        sep.frame = bounds
                
        layoutBotView()
            
        layoutTopView()
        
        let profileSize: CGFloat = 42
        profileView.frame = CGRect(x: Constants.smallMargin, y: 4,
            width: profileSize, height: profileSize).integral
                
        streakLabel.sizeToFit()
        let labelWidth = streakLabel.bounds.width
        let flameWidth: CGFloat = 30
        let totalStreakWidth = labelWidth + flameWidth + 2
        streakView.frame = CGRect(
            x: self.bounds.maxX - totalStreakWidth - Constants.margin, y: 4,
            width: totalStreakWidth, height: profileSize)
        
        streakAnimation.frame = CGRect(
            x: 0, y: self.streakView.bounds.midY - flameWidth / 2,
            width: flameWidth, height: flameWidth).insetBy(dx: -8, dy: -8)
        
        streakLabel.frame.origin = CGPoint(
            x: self.streakView.bounds.maxX - streakLabel.bounds.width,
            y: self.streakView.bounds.midY - streakLabel.bounds.height / 2)
        
        if !isSidebarLayout {
            label.sizeToFit()
            label.center = CGPoint(x: topView.bounds.midX, y: profileView.center.y)
            label.frame = label.frame.integral
        }
        else {
            label.sizeToFit()
            label.frame = CGRect(
                x: Constants.margin, y: safeAreaInsets.top + 30 - label.bounds.height/2,
                width: 300, height: label.bounds.height).integral
        }
        
    }
    
    private func layoutTopView() {
        if !isSidebarLayout {
            let height = self.minHeight
            if isAnimatingFocus {
                topView.frame = CGRect(x: 0, y: safeAreaInsets.top, width: self.bounds.width, height: height)
            }
            else {
                topView.frame = CGRect(x: 0, y: botView.frame.minY - height, width: self.bounds.width, height: height)
            }
        }
        else {
            let height = self.minHeight
            topView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: height)
        }
        
    }
    
    private func layoutBotView() {
        if !isSidebarLayout {
            if isBotViewFocused {
                botView.frame = CGRect(
                    x: 0, y: self.safeAreaInsets.top,
                    width: self.bounds.width,
                    height: self.height - self.minHeight)
            }
            else {
                let maxHeight = self.height - self.minHeight
                let adjustedMaxHeight = self.height + self.safeAreaInsets.top
                let height = max(0, maxHeight - (adjustedMaxHeight - self.bounds.height))
                
                botView.frame = CGRect(x: 0, y: self.bounds.maxY - height, width:
                    self.bounds.width, height: height)
            }
        }
        else {
            let width: CGFloat = min(360, bounds.width*0.7)
            botView.frame = CGRect(
                x: bounds.maxX - width,
                y: bounds.maxY - height,
                width: width,
                height: height)
        }
        
        for subView in botView.subviews {
            if let view = subView as? HeaderAccessoryView {
                view.isSidebarLayout = self.isSidebarLayout
            }
            subView.frame = botView.bounds
        }
        
    }
    
    @objc func didTapStreakView() {
        streakViewHandler?()
    }
    
    public func setFocused(_ focused: Bool, isScrolledToTop: Bool) {
        isBotViewFocused = focused
        
        if self.isSidebarLayout { return }
        
        if focused {
            UIView.animateWithCurve(duration: 0.3, curve: UIView.CustomAnimationCurve.cubic.easeOut) {
                self.topView.alpha = 0
                self.layoutSubviews()
            } completion: { }
        }
        else {
            isAnimatingFocus = true
            
            if !isScrolledToTop {
                topView.frame = CGRect(x: 0, y: safeAreaInsets.top, width: self.bounds.width, height: self.minHeight)
            }
            
            UIView.animateWithCurve(duration: 0.3, curve: UIView.CustomAnimationCurve.cubic.easeOut) {
                self.topView.alpha = 1
                self.botView.alpha = (isScrolledToTop || self.isSidebarLayout) ? 1 : 0
                
                if isScrolledToTop, !self.isSidebarLayout {
                    self.botView.frame = CGRect(
                        x: 0, y: self.bounds.maxY - (self.height - self.minHeight),
                        width: self.bounds.width,
                        height: self.height - self.minHeight)
                } else {
                    self.botView.frame = CGRect(
                        x: 0, y: self.safeAreaInsets.top - 10,
                        width: self.bounds.width,
                        height: self.height - self.minHeight)
                }
                
                self.layoutTopView()
                
            } completion: {
                self.isAnimatingFocus = false
                self.layoutSubviews()
                self.botView.alpha = 1
            }
        }
        
    }
    
    
    
}

class HeaderAccessoryView: UIView {
    public var isSidebarLayout = false
}

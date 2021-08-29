//
//  HeaderView.swift
//  Andante
//
//  Created by Miles Vinson on 6/21/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

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
    
    @objc func reloadStreak() {
        let streak = PracticeDatabase.shared.currentStreak()
        streakView.setTitle("🔥 \(streak)", for: .normal)
        streakView.setTitleColor(streak == 0 ? Colors.lightText : Colors.text, for: .normal)
    }
    
    init() {
        super.init(frame: .zero)
                
        backgroundColor = Colors.barColor
        
        addSubview(topView)
        
        streakView.setTitle("🔥 0", for: .normal)
        streakView.setTitleColor(Colors.text, for: .normal)
        streakView.titleLabel?.font = Fonts.semibold.withSize(17)
        streakView.addTarget(self, action: #selector(didTapStreakView), for: .touchUpInside)
        streakView.contentHorizontalAlignment = .right
        streakView.titleEdgeInsets.right = Constants.margin
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
            
            height = 124
            minHeight = 52
        }
        else {
            profileView.isHidden = true
            streakView.isHidden = true
            label.font = Fonts.bold.withSize(20)
            
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
                
        let width = streakView.titleLabel!.sizeThatFits(self.bounds.size).width + Constants.margin + 10
        streakView.frame = CGRect(
            x: self.bounds.maxX - width, y: 4,
            width: width, height: profileSize)
        
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

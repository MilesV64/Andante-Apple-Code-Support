//
//  Tabbar.swift
//  Andante
//
//  Created by Miles Vinson on 11/1/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

extension UIView {
    func setBarShadow() {
        if traitCollection.userInterfaceStyle == .dark {
            self.setShadow(radius: 8, yOffset: 0, opacity: 0.28)
        } else {
            self.setShadow(radius: 8, yOffset: 0, opacity: 0.18)
        }
        self.layer.shadowColor = Colors.barShadowColor.cgColor
    }
}

class Tabbar: NavigationComponent {
    
    private let sep = Separator(position: .top)
    
    private let sessionsTab = TabView(.sessions)
    private let statsTab = TabView(.stats)
    private let journalTab = TabView(.journal)
    
    init(_ selectedTab: Int = 0) {
        super.init(frame: .zero)
        
        self.backgroundColor = Colors.barColor
        
        setBarShadow()
        
        addSubview(sep)
        
        [sessionsTab, statsTab, journalTab].enumerated().forEach { (i, tab) in
            tab.action = {
                [weak self] in
                guard let self = self else { return }
                self.setSelectedTab(i)
                self.delegate?.navigationComponentDidSelect(index: i)
            }
            self.addSubview(tab)
            
            tab.setSelected(i == selectedTab)
        }
        
        sessionsTab.longPressAction = {
            [weak self] in
            guard let self = self else { return }
            if UIDevice.current.userInterfaceIdiom == .phone {
                self.delegate?.navigationComponentDidRequestChangeProfile(
                    sourceView: self.sessionsTab,
                    sourceRect: CGRect(
                        x: self.sessionsTab.bounds.midX - 1,
                        y: self.sessionsTab.bounds.midY - 6,
                        width: 2, height: 2),
                    arrowDirection: .down)
            }
            
        }
                
    }
    
    override func setSelectedTab(_ index: Int) {
        [sessionsTab, statsTab, journalTab].enumerated().forEach { (i, tab) in
            tab.setSelected(i == index)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setBarShadow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        sep.frame = self.bounds
        
        let tabWidth = bounds.width/3
        
        [sessionsTab, statsTab, journalTab].enumerated().forEach { (i, tab) in
            tab.frame = CGRect(
                x: CGFloat(i)*tabWidth,
                y: 0,
                width: tabWidth,
                height: 49)
        }
        
    }
    
    private class TabView: CustomButton {
        
        private var unselectedColor: UIColor {
            return Colors.dynamicColor(light: UIColor("#627784").withAlphaComponent(0.9), dark: UIColor("#8799A5").withAlphaComponent(0.9))
        }
        
        private let imgView = UIImageView()
        private let label = UILabel()
        private var isSelectedTab = false
        private var tab: NavigationComponent.Tab = .sessions
        
        private let longPressGesture = UILongPressGestureRecognizer()
        public var longPressAction: (()->Void)?
        
        init(_ tab: NavigationComponent.Tab) {
            super.init()
            
            self.tintAdjustmentMode = .normal
            
            self.tab = tab
            
            imgView.image = tab.icon
            imgView.isUserInteractionEnabled = false
            self.addSubview(imgView)
            
            label.text = tab.string
            label.textAlignment = .center
            label.isUserInteractionEnabled = false
            self.addSubview(label)
            
            longPressGesture.minimumPressDuration = 0.5
            longPressGesture.addTarget(self, action: #selector(didLongPress(_:)))
            self.addGestureRecognizer(longPressGesture)
            
        }
        
        @objc func didLongPress(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began {
                longPressAction?()
            }
        }
        
        var fontSize: CGFloat {
            return traitCollection.horizontalSizeClass == .compact ? 11 : 14
        }
        
        func setSelected(_ selected: Bool) {
            isSelectedTab = selected
            
            if selected {
                imgView.setImageColor(color: Colors.orange)
                label.font = Fonts.semibold.withSize(fontSize)
                label.textColor = Colors.orange
            }
            else {
                imgView.setImageColor(color: unselectedColor)
                label.font = Fonts.medium.withSize(fontSize)
                label.textColor = unselectedColor
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError()
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            setSelected(isSelectedTab)
            
            if traitCollection.horizontalSizeClass == .compact {
                imgView.center = CGPoint(x: Int(bounds.midX), y: Int(bounds.height/2 - 6))
                imgView.bounds.size = CGSize(20)
                
                label.frame = CGRect(x: 0, y: self.bounds.maxY - 20, width: self.bounds.width, height: 18)
            }
            else {
                var offset: CGFloat = 2
                if tab == .journal {
                    offset = 0
                }
                imgView.bounds.size = CGSize(22)
                label.sizeToFit()
                let width = imgView.bounds.width + label.bounds.width + 8
                let minX = bounds.midX - width/2
                imgView.frame.origin = CGPoint(
                    x: minX, y: bounds.midY - imgView.bounds.height/2 - offset)
                label.frame.origin = CGPoint(
                    x: imgView.frame.maxX + 8, y: bounds.midY - label.bounds.height/2)
            }
                        
            
            
        }
    }
}

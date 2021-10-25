//
//  MultipleProfilesView.swift
//  Andante
//
//  Created by Miles on 10/24/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class MultipleProfilesView: PushButton {
    
    private var profileViews: [ProfileImageContainerView] = []
    private var moreProfilesView: MoreProfilesView?
    
    public var profileInsets: CGFloat = 3 {
        didSet {
            profileViews.forEach { $0.inset = profileInsets }
            moreProfilesView?.inset = profileInsets
        }
    }
    
    public var containerBackgroundColor: UIColor? {
        didSet {
            profileViews.forEach { $0.backgroundColor = containerBackgroundColor }
            moreProfilesView?.backgroundColor = containerBackgroundColor
        }
    }
    
    public func setProfiles(_ profiles: [CDProfile]) {
        
        profileViews.forEach {
            $0.removeFromSuperview()
        }
        profileViews.removeAll()
        
        if profiles.count > 3 {
            profiles.prefix(2).forEach { profile in
                let profileView = ProfileImageContainerView()
                profileView.profileImageView.profile = profile
                profileView.inset = self.profileInsets
                profileView.backgroundColor = self.containerBackgroundColor
                self.addSubview(profileView)
                self.profileViews.append(profileView)
            }
            
            if self.moreProfilesView != nil {
                self.moreProfilesView?.count = (profiles.count - 2)
            }
            else {
                let moreProfilesView = MoreProfilesView()
                moreProfilesView.count = (profiles.count - 2)
                moreProfilesView.inset = profileInsets
                moreProfilesView.backgroundColor = self.containerBackgroundColor
                self.addSubview(moreProfilesView)
                self.moreProfilesView = moreProfilesView
            }
            
        }
        else {
            moreProfilesView?.removeFromSuperview()
            moreProfilesView = nil
            
            profiles.forEach { profile in
                let profileView = ProfileImageContainerView()
                profileView.profileImageView.profile = profile
                profileView.inset = self.profileInsets
                profileView.backgroundColor = self.containerBackgroundColor
                self.addSubview(profileView)
                self.profileViews.append(profileView)
            }
            
        }
        
        self.setNeedsLayout()
        
    }
    
    private static let spacingRatio: CGFloat = 0.4
    
    public func calculateWidth() -> CGFloat {
        let itemSize: CGFloat = self.bounds.height
        let spacing: CGFloat = floor(itemSize * Self.spacingRatio)
        
        let count = CGFloat(min(3, self.profileViews.count))
        
        return (itemSize * count) - (spacing * (count - 1))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let itemSize: CGFloat = self.bounds.height
        let spacing: CGFloat = floor(itemSize * Self.spacingRatio)
        
        var views: [UIView] = []
        views.append(contentsOf: self.profileViews)
        if let moreProfilesView = moreProfilesView {
            views.append(moreProfilesView)
        }
        
        for (index, view) in views.enumerated() {
            let index = CGFloat(index)
            view.frame = CGRect(
                x: (index * itemSize) - (index * spacing),
                y: 0,
                width: itemSize,
                height: itemSize
            )
        }
    }
    
}

fileprivate class ProfileImageContainerView: UIView {
    
    let profileImageView = ProfileImageView()
    
    public var inset: CGFloat = 2 {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = Colors.foregroundColor
        self.addSubview(self.profileImageView)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.profileImageView.frame = self.bounds.insetBy(dx: inset, dy: inset)
        self.profileImageView.inset = self.bounds.height * 0.14
        self.roundCorners(self.bounds.height / 2, prefersContinuous: false)
    }
}

fileprivate class MoreProfilesView: UIView {
    
    public var inset: CGFloat = 2 {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    public var count = 0
    
    private let fgView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = Colors.foregroundColor
        
        fgView.backgroundColor = Colors.lightColor
        self.addSubview(fgView)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.fgView.frame = self.bounds.insetBy(dx: inset, dy: inset)
        self.roundCorners(self.bounds.height / 2, prefersContinuous: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
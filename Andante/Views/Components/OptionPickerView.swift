//
//  OptionPickerView.swift
//  Andante
//
//  Created by Miles Vinson on 9/26/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class OptionPickerView: UIView {
    
    public let bgView = CustomButton()
    public let titleLabel = UILabel()
    
    public var selectHandler: (()->Void)?
    
    public var margin: CGFloat = Constants.smallMargin

    init(_ title: String) {
        super.init(frame: .zero)
        
        bgView.backgroundColor = Colors.lightColor
        bgView.roundCorners(12)
        bgView.action = {
            [weak self] in
            guard let self = self else { return }
            self.selectHandler?()
        }
        self.addSubview(bgView)
        
        titleLabel.text = title
        titleLabel.font = Fonts.medium.withSize(16)
        titleLabel.textColor = Colors.text
        bgView.addSubview(titleLabel)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(
            width: self.window!.bounds.width,
            height: 50
        )
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bgView.frame = self.bounds.insetBy(dx: margin, dy: 0)
        
        titleLabel.sizeToFit()
        titleLabel.frame.origin = CGPoint(
            x: Constants.margin,
            y: bgView.bounds.midY - titleLabel.bounds.height/2
        )
        
    }
}

class ProfileOptionPickerView: OptionPickerView {
    
    private let profileButton = CustomButton()
    
    public var profile: CDProfile? {
        didSet {
            profileButton.setTitle(profile?.name ?? "", for: .normal)
            setNeedsLayout()
        }
    }
        
    init() {
        super.init("Profile")
        
        profileButton.setTitleColor(Colors.orange, for: .normal)
        profileButton.titleLabel?.font = Fonts.medium.withSize(16)
        profileButton.contentHorizontalAlignment = .right
        profileButton.contentEdgeInsets.right = Constants.margin
        profileButton.highlightAction = {
            [weak self] highlighted in
            guard let self = self else { return }
            if highlighted {
                self.profileButton.alpha = 0.2
            }
            else {
                UIView.animate(withDuration: 0.25) {
                    self.profileButton.alpha = 1
                }
            }
        }
        profileButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.selectHandler?()
        }
        
        bgView.addSubview(profileButton)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = profileButton.titleLabel!.sizeThatFits(self.bounds.size).width
        
        let minX = titleLabel.frame.maxX + 14
        profileButton.frame = CGRect(
            from: CGPoint(
                x: max(minX, bgView.bounds.maxX - width - Constants.margin*2),
                y: 0
            ),
            to: CGPoint(
                x: bgView.bounds.maxX,
                y: bgView.bounds.maxY
            )
        )
        
    }
}

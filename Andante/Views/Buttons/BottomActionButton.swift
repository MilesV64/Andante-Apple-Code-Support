//
//  BottomActionButton.swift
//  Andante
//
//  Created by Miles Vinson on 7/18/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class BottomActionButton: Separator {
    
    enum Style {
        case regular, floating
    }
    
    public let button = PushButton()
    
    public var title: String? {
        get {
            return button.title(for: .normal)
        }
        set {
            if let title = newValue {
                button.setTitle(title, for: .normal)
            }
        }
    }
    
    public var action: (()->Void)? {
        didSet {
            button.action = action
        }
    }
    
    public var style: BottomActionButton.Style = .regular {
        didSet {
            if style == .regular {
                self.backgroundColor = Colors.foregroundColor
            } else {
                self.backgroundColor = Colors.backgroundColor
            }
            button.setButtonShadow(floating: style == .floating)
        }
    }
    
    init(title: String) {
        super.init(frame: .zero)
        
        self.position = .top
        self.color = Colors.barSeparator
        self.backgroundColor = Colors.foregroundColor
        
        button.backgroundColor = Colors.orange
        button.setTitle(title, color: Colors.white, font: Fonts.semibold.withSize(17))
        button.setButtonShadow(floating: style == .floating)
        button.action = action
        self.addSubview(button)
        
        self.title = title
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public static var height: CGFloat {
        return 52 + 34
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let buttonHeight: CGFloat = 52
        let padding: CGFloat = 34
        let extraSpace = buttonHeight + padding
        let bottomSpace: CGFloat = superview?.safeAreaInsets.bottom ?? 0
        
        return CGSize(
            width: size.width,
            height: extraSpace + bottomSpace)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        button.frame = CGRect(
            x: Constants.margin, y: 16,
            width: self.bounds.width - Constants.margin*2,
            height: 50)
        button.cornerRadius = 12
        
    }
}

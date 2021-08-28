//
//  PopupViewAreYouSureView.swift
//  Andante
//
//  Created by Miles Vinson on 2/18/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class PopupAreYouSureView: PopupContentView {
    
    private let titleLabel = UILabel()
    private let textView = UITextView()
    private let separator = Separator()
    
    private let destructiveButton = PushButton()
    private let cancelButton = PushButton()
    
    
    public var destructiveAction: (()->Void)?
    
    public var cancelAction: (()->Void)? {
        didSet {
            cancelButton.action = cancelAction
        }
    }
    
    private var didSelectDestructive = false
    
    private var isDestructive = true
    
    init(
        _ vc: TransitionPopupViewController,
        isDistructive: Bool = true,
        title: String? = "Are you sure?",
        description: String? = nil,
        destructiveText: String?,
        cancelText: String? = "Cancel",
        destructiveAction: (()->Void)?
    ) {
        
        super.init()
        
        self.isDestructive = isDistructive
        
        titleLabel.text = title
        textView.text = description
        
        let textColor = isDestructive ? Colors.red : Colors.white

        cancelButton.setTitle(cancelText ?? "Cancel", color: Colors.text, font: Fonts.semibold.withSize(17))
        destructiveButton.setTitle(destructiveText ?? "", color: textColor, font: Fonts.medium.withSize(17))
        
        self.destructiveAction = destructiveAction
        
        titleLabel.textColor = Colors.text
        titleLabel.font = Fonts.semibold.withSize(18)
        titleLabel.textAlignment = .center
        self.addSubview(titleLabel)
        
        textView.font = Fonts.regular.withSize(16)
        textView.textColor = Colors.lightText
        textView.textContainerInset.left = Constants.margin + 5
        textView.textContainerInset.right = Constants.margin + 5
        textView.textAlignment = .center
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.backgroundColor = .clear
        self.addSubview(textView)
        
        cancelButton.backgroundColor = Colors.lightColor
        cancelButton.cornerRadius = 10
        cancelButton.action = cancelAction
        self.addSubview(cancelButton)
        
        let buttonColor = isDestructive ? Colors.red.withAlphaComponent(0.13) : Colors.orange
        
        destructiveButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.destructiveAction?()
        }
        destructiveButton.backgroundColor = buttonColor
        destructiveButton.cornerRadius = 10
        self.addSubview(destructiveButton)
        
        separator.insetToMargins()
        separator.position = .top
        self.addSubview(separator)
        
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func preferredHeight(for width: CGFloat) -> CGFloat {
        let buttonHeight: CGFloat = 50
        let buttonSpacing: CGFloat = 10
        let titleHeight = titleLabel.sizeThatFits(CGSize(width: width, height: .infinity)).height
        let textHeight = textView.sizeThatFits(CGSize(width: width, height: CGFloat.infinity)).height
        
        return titleHeight + textHeight + buttonHeight*2 + buttonSpacing*3 + 16 + 10 + 16
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let buttonHeight: CGFloat = 50
        let buttonSpacing: CGFloat = 10
        
        let titleHeight = titleLabel.sizeThatFits(CGSize(width: bounds.width, height: .infinity)).height
        let textHeight = textView.sizeThatFits(CGSize(width: bounds.width, height: CGFloat.infinity)).height
                
        titleLabel.frame = CGRect(x: 0, y: 16, width: bounds.width, height: titleHeight)
        textView.frame = CGRect(x: 0, y: titleLabel.frame.maxY, width: bounds.width, height: textHeight)
        
        separator.frame = CGRect(
            x: 0, y: textView.frame.maxY + 10,
            width: bounds.width,
            height: 6)
        
        destructiveButton.frame = CGRect(
            x: Constants.margin, y: separator.frame.maxY + buttonSpacing,
            width: bounds.width - Constants.margin*2,
            height: buttonHeight)
        
        cancelButton.frame = CGRect(
            x: Constants.margin, y: destructiveButton.frame.maxY + buttonSpacing,
            width: bounds.width - Constants.margin*2,
            height: buttonHeight)
        
        
    }
    
    private class Button: CustomButton {
        
        let separator = Separator(position: .top)
        
        init(destructive: Bool) {
            super.init()
            
            self.addSubview(separator)
            
            self.setTitleColor(destructive ? Colors.red : Colors.text, for: .normal)
            self.titleLabel?.font = destructive ? Fonts.semibold.withSize(17) : Fonts.semibold.withSize(17)
            
            self.highlightAction = {
                [weak self] highlighted in
                guard let self = self else { return }
                
                if highlighted {
                    self.titleLabel?.alpha = 0.25
                }
                else {
                    UIView.animate(withDuration: 0.2) {
                        self.titleLabel?.alpha = 1
                    }
                }
                
            }
            
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            separator.frame = self.bounds
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
}


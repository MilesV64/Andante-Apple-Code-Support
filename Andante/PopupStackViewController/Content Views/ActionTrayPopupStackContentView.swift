//
//  ActionTrayPopupStackContentView.swift
//  Andante
//
//  Created by Miles on 10/29/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class ActionTrayPopupStackContentView: PopupStackContentView {
    
    static let buttonHeight: CGFloat = 48
    static let outerButtonSpacing: CGFloat = Constants.margin
    static let interButtonSpacing: CGFloat = 12
    
    override func preferredHeight(for width: CGFloat) -> CGFloat {
        let titleHeight = self.titleLabel.sizeThatFits(CGSize(width: width, height: .infinity)).height
        let textHeight = self.textView.sizeThatFits(CGSize(width: width, height: .infinity)).height
        
        var height = 40 + titleHeight + textHeight
        height += Self.buttonHeight + Self.outerButtonSpacing*2
        
        if self.actionButton != nil {
            height += Self.buttonHeight + Self.interButtonSpacing
        }
        
        return height
    }
    
    private let titleLabel = UILabel()
    private let textView = UITextView()
    
    private var actionButton: Button?
    private let cancelButton = Button()
    
    private var action: (()->Void)?
    
    public var cancelAction: (()->Void)?
    
    private var didSelectAction = false
    
    private var isDestructive = true
    
    init(title: String, description: String? = nil, cancelText: String? = "Cancel") {
        super.init(frame: .zero)
        
        titleLabel.text = title
        textView.text = description
        
        titleLabel.textColor = Colors.text
        titleLabel.font = Fonts.semibold.withSize(19)
        titleLabel.textAlignment = .center
        self.addSubview(titleLabel)
        
        textView.font = Fonts.regular.withSize(17)
        textView.textColor = Colors.lightText
        textView.textContainerInset.left = Constants.margin + 5
        textView.textContainerInset.right = Constants.margin + 5
        textView.textAlignment = .center
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.backgroundColor = .clear
        self.addSubview(textView)
        
        cancelButton.setTitle(cancelText ?? "Cancel", color: Colors.text, font: Fonts.semibold.withSize(17))
        cancelButton.action = {
            [weak self] in
            guard let self = self else { return }
            if let popupVC = self.popupViewController {
                if popupVC.contentViews.count > 1 {
                    popupVC.pop()
                }
                else {
                    popupVC.hide {
                        self.cancelAction?()
                    }
                }
            }
        }
        self.addSubview(cancelButton)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let titleHeight = titleLabel.sizeThatFits(CGSize(width: self.bounds.width, height: .infinity)).height
        let textHeight = textView.sizeThatFits(CGSize(width: self.bounds.width, height: CGFloat.infinity)).height
        
        titleLabel.frame = CGRect(x: 0, y: 40, width: self.bounds.width, height: titleHeight)
        textView.frame = CGRect(x: 0, y: titleLabel.frame.maxY, width: self.bounds.width, height: textHeight)
        
        if let actionButton = actionButton {
            actionButton.frame = CGRect(
                x: Constants.margin, y: textView.frame.maxY + Self.outerButtonSpacing,
                width: self.bounds.width - Constants.margin*2,
                height: Self.buttonHeight)
            
            cancelButton.frame = CGRect(
                x: Constants.margin, y: actionButton.frame.maxY + Self.interButtonSpacing,
                width: self.bounds.width - Constants.margin*2,
                height: Self.buttonHeight)
        }
        else {
            cancelButton.frame = CGRect(
                x: Constants.margin, y: textView.frame.maxY + Self.outerButtonSpacing,
                width: self.bounds.width - Constants.margin*2,
                height: Self.buttonHeight)
        }
        
    }
    
    public func addAction(_ title: String, isDestructive: Bool = false, handler: (() -> ())?) {
        self.action = handler
        
        let actionButton = Button()
        actionButton.setTitle(title, color: isDestructive ? Colors.red : Colors.orange, font: Fonts.semibold.withSize(17))
        actionButton.action = { [weak self] in
            self?.action?()
        }
        
        self.addSubview(actionButton)
        self.actionButton = actionButton
        
        self.setNeedsLayout()
        
    }
    
    private class Button: PushButton {
        
        override init() {
            super.init()
            
            self.backgroundColor = Colors.extraLightColor
            self.cornerRadius = 14

        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
}

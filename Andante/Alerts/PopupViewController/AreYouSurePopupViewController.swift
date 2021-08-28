//
//  AreYouSurePopupViewController.swift
//  Andante
//
//  Created by Miles Vinson on 2/22/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class AreYouSurePopupViewController: PopupViewController {
    
    private let titleLabel = UILabel()
    private let textView = UITextView()
    private let separator = Separator()
    
    public var titleText: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    public var descriptionText: String? {
        didSet {
            textView.text = description
        }
    }
    
    public var destructiveText: String? {
        didSet {
            destructiveButton.setTitle(destructiveText, for: .normal)
        }
    }
    
    public var cancelText: String? {
        didSet {
            cancelButton.setTitle(cancelText, for: .normal)
        }
    }
    
    private let destructiveButton = PushButton()
    private let cancelButton = PushButton()
    
    public var destructiveAction: (()->Void)?
    
    public var cancelAction: (()->Void)?
    
    private var didSelectDestructive = false
    
    private var isDestructive = true
    
    convenience init(isDistructive: Bool = true, title: String? = "Are you sure?", description: String? = nil, destructiveText: String?, cancelText: String? = "Cancel", destructiveAction: (()->Void)?) {
        self.init()
        
        self.isDestructive = isDistructive
        
        titleLabel.text = title
        textView.text = description
        
        self.destructiveText = destructiveText
        self.cancelText = cancelText
        
        self.destructiveAction = destructiveAction
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.textColor = Colors.text
        titleLabel.font = Fonts.semibold.withSize(18)
        titleLabel.textAlignment = .center
        self.contentView.addSubview(titleLabel)
        
        textView.font = Fonts.regular.withSize(16)
        textView.textColor = Colors.lightText
        textView.textContainerInset.left = Constants.margin + 5
        textView.textContainerInset.right = Constants.margin + 5
        textView.textAlignment = .center
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.backgroundColor = .clear
        self.contentView.addSubview(textView)
        
        cancelButton.setTitle(cancelText ?? "Cancel", color: Colors.text, font: Fonts.semibold.withSize(17))
        cancelButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.close()
        }
        cancelButton.backgroundColor = Colors.lightColor
        cancelButton.cornerRadius = 10
        self.contentView.addSubview(cancelButton)
        
        let textColor = isDestructive ? Colors.red : Colors.white
        let buttonColor = isDestructive ? Colors.red.withAlphaComponent(0.13) : Colors.orange
        
        destructiveButton.setTitle(destructiveText ?? "", color: textColor, font: Fonts.medium.withSize(17))
        destructiveButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.didSelectDestructive = true
            self.close()
        }
        destructiveButton.backgroundColor = buttonColor
        destructiveButton.cornerRadius = 10
        self.contentView.addSubview(destructiveButton)
        
        separator.insetToMargins()
        separator.position = .top
        self.contentView.addSubview(separator)
        
    }
    
    override func viewDidLayoutSubviews() {
        
        let buttonHeight: CGFloat = 50
        let buttonSpacing: CGFloat = 10
        
        let titleHeight = titleLabel.sizeThatFits(CGSize(width: contentWidth, height: .infinity)).height
        let textHeight = textView.sizeThatFits(CGSize(width: contentWidth, height: CGFloat.infinity)).height
        
        let totalTextHeight: CGFloat = titleHeight + textHeight
        let totalButtonHeight: CGFloat = buttonHeight*2 + buttonSpacing*3
        
        self.preferredContentHeight = totalTextHeight + totalButtonHeight + 16 + 10 + 16
        
        super.viewDidLayoutSubviews()
        
        titleLabel.frame = CGRect(x: 0, y: 16, width: self.contentView.bounds.width, height: titleHeight)
        textView.frame = CGRect(x: 0, y: titleLabel.frame.maxY, width: self.contentView.bounds.width, height: textHeight)
        
        separator.frame = CGRect(
            x: 0, y: textView.frame.maxY + 10,
            width: contentView.bounds.width,
            height: 6)
        
        destructiveButton.frame = CGRect(
            x: Constants.margin, y: separator.frame.maxY + buttonSpacing,
            width: contentView.bounds.width - Constants.margin*2,
            height: buttonHeight)
        
        cancelButton.frame = CGRect(
            x: Constants.margin, y: destructiveButton.frame.maxY + buttonSpacing,
            width: contentView.bounds.width - Constants.margin*2,
            height: buttonHeight)
        
        
    }
    
    override func close() {
        if didSelectDestructive {
            self.closeCompletion = {
                [weak self] in
                guard let self = self else { return }
                self.destructiveAction?()
            }
        }
        else {
            cancelAction?()
        }
        
        super.close()
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

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
    
    private let destructiveButton = Button(destructive: true)
    private let cancelButton = Button(destructive: false)
    
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
        
        cancelButton.setTitle(cancelText ?? "Cancel", color: Colors.lightText, font: Fonts.medium.withSize(19))
        cancelButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.close()
        }
        self.contentView.addSubview(cancelButton)
        
        let textColor = isDestructive ? Colors.red : Colors.orange
        destructiveButton.setTitle(destructiveText ?? "", color: textColor, font: Fonts.medium.withSize(19))
        destructiveButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.didSelectDestructive = true
            self.close()
        }
        self.contentView.addSubview(destructiveButton)
                
    }
    
    override func viewDidLayoutSubviews() {
        
        let buttonHeight: CGFloat = 70
        
        let titleHeight = titleLabel.sizeThatFits(CGSize(width: contentWidth, height: .infinity)).height
        let textHeight = textView.sizeThatFits(CGSize(width: contentWidth, height: CGFloat.infinity)).height
        
        let totalTextHeight: CGFloat = titleHeight + textHeight
        let totalButtonHeight: CGFloat = buttonHeight*2
        
        self.preferredContentHeight = totalTextHeight + totalButtonHeight + 20 + 20
        
        super.viewDidLayoutSubviews()
        
        titleLabel.frame = CGRect(x: 0, y: 20, width: self.contentView.bounds.width, height: titleHeight)
        textView.frame = CGRect(x: 0, y: titleLabel.frame.maxY, width: self.contentView.bounds.width, height: textHeight)
        
        destructiveButton.frame = CGRect(
            x: 0, y: textView.frame.maxY + 20,
            width: contentView.bounds.width,
            height: buttonHeight)
        
        cancelButton.frame = CGRect(
            x: 0, y: destructiveButton.frame.maxY,
            width: contentView.bounds.width,
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
                    self.backgroundColor = Colors.cellHighlightColor
                }
                else {
                    UIView.animate(withDuration: 0.2) {
                        self.backgroundColor = .clear
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

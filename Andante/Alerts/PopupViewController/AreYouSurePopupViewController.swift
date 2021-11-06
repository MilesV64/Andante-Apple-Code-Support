//
//  AreYouSurePopupViewController.swift
//  Andante
//
//  Created by Miles Vinson on 2/22/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class ActionTrayPopupViewController: PopupViewController {
    
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
    
    public var cancelText: String? {
        didSet {
            cancelButton.setTitle(cancelText, for: .normal)
        }
    }
    
    private var actionButton: Button?
    private let cancelButton = Button()
    
    private var action: (()->Void)?
    
    public var cancelAction: (()->Void)?
    
    private var didSelectAction = false
    
    private var isDestructive = true
    
    convenience init(title: String, description: String? = nil, cancelText: String? = "Cancel") {
        self.init()
        
        self.isDestructive = isDestructive
        
        titleLabel.text = title
        textView.text = description
        
        self.cancelText = cancelText
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.textColor = Colors.text
        titleLabel.font = Fonts.semibold.withSize(19)
        titleLabel.textAlignment = .center
        self.contentView.addSubview(titleLabel)
        
        textView.font = Fonts.regular.withSize(17)
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
            
    }
    
    override func viewDidLayoutSubviews() {
        
        let buttonHeight: CGFloat = 70
        
        let titleHeight = titleLabel.sizeThatFits(CGSize(width: contentWidth, height: .infinity)).height
        let textHeight = textView.sizeThatFits(CGSize(width: contentWidth, height: CGFloat.infinity)).height
        
        let totalTextHeight: CGFloat = titleHeight + textHeight
        let totalButtonHeight: CGFloat = buttonHeight * (actionButton == nil ? 1 : 2)
        
        self.preferredContentHeight = totalTextHeight + totalButtonHeight + 20 + 20
        
        super.viewDidLayoutSubviews()
        
        titleLabel.frame = CGRect(x: 0, y: 20, width: self.contentView.bounds.width, height: titleHeight)
        textView.frame = CGRect(x: 0, y: titleLabel.frame.maxY, width: self.contentView.bounds.width, height: textHeight)
        
        if let actionButton = actionButton {
            actionButton.frame = CGRect(
                x: 0, y: textView.frame.maxY + 20,
                width: contentView.bounds.width,
                height: buttonHeight)
        }
        
        cancelButton.frame = CGRect(
            x: 0, y: (actionButton?.frame.maxY) ?? (textView.frame.maxY + 20),
            width: contentView.bounds.width,
            height: buttonHeight)
        
        
    }
    
    public func addAction(_ title: String, isDestructive: Bool = false, handler: (() -> ())?) {
        self.action = handler
        
        let actionButton = Button()
        actionButton.setTitle(title, color: isDestructive ? Colors.red : Colors.orange, font: Fonts.medium.withSize(19))
        actionButton.action = { [weak self] in
            self?.didSelectAction = true
            self?.close()
        }
        self.contentView.addSubview(actionButton)
        self.actionButton = actionButton
        
        self.view.setNeedsLayout()
    }
    
    override func close() {
        if didSelectAction {
            self.closeCompletion = {
                [weak self] in
                guard let self = self else { return }
                self.action?()
            }
        }
        else {
            cancelAction?()
        }
        
        super.close()
    }
    
    private class Button: CustomButton {
        
        let separator = Separator(position: .top)
        
        override init() {
            super.init()
            
            self.addSubview(separator)
            
            self.titleLabel?.font = Fonts.semibold.withSize(17)
            
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

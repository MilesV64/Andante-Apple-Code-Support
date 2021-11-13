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
        
        cancelButton.setTitle(cancelText ?? "Cancel", color: Colors.lightText, font: Fonts.medium.withSize(17))
        cancelButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.close()
        }
        self.contentView.addSubview(cancelButton)
            
    }
    
    override func viewDidLayoutSubviews() {
        
        let buttonHeight: CGFloat = 50
        let buttonSpacing: CGFloat = 10
        
        let titleHeight = titleLabel.sizeThatFits(CGSize(width: contentWidth, height: .infinity)).height
        let textHeight = textView.sizeThatFits(CGSize(width: contentWidth, height: CGFloat.infinity)).height
        
        let totalTextHeight: CGFloat = titleHeight + textHeight
        let totalButtonHeight: CGFloat = (buttonHeight * (actionButton == nil ? 1 : 2)) + (actionButton == nil ? 0 : buttonSpacing)
        
        
        self.preferredContentHeight = totalTextHeight + totalButtonHeight + 20 + 20 + 20
        
        super.viewDidLayoutSubviews()
        
        titleLabel.frame = CGRect(x: 0, y: 20, width: self.contentView.bounds.width, height: titleHeight)
        textView.frame = CGRect(x: 0, y: titleLabel.frame.maxY, width: self.contentView.bounds.width, height: textHeight)
        
        var cancelMinY: CGFloat = textView.frame.maxY + 20
        
        if let actionButton = actionButton {
            actionButton.frame = CGRect(
                x: 20, y: textView.frame.maxY + 20,
                width: contentView.bounds.width - 40,
                height: buttonHeight)
            cancelMinY = actionButton.frame.maxY + buttonSpacing
        }
        
        cancelButton.frame = CGRect(
            x: 20, y: cancelMinY,
            width: contentView.bounds.width - 40,
            height: buttonHeight)
        
        
    }
    
    public func addAction(_ title: String, isDestructive: Bool = false, handler: (() -> ())?) {
        self.action = handler
        
        let actionButton = Button()
        actionButton.backgroundColor = isDestructive ? Colors.extraLightColor : Colors.orange
        actionButton.setTitle(title, color: isDestructive ? Colors.red : UIColor.white, font: Fonts.medium.withSize(17))
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
    
    private class Button: PushButton {
        
        override init() {
            super.init()
            
            self.cornerRadius = 14
            self.backgroundColor = Colors.lightColor
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
}

//
//  DescriptionActionAlertController.swift
//  Andante
//
//  Created by Miles Vinson on 5/30/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class DescriptionActionAlertController: PickerAlertController {
    
    public static func PlaceholderAlert() -> DescriptionActionAlertController {
        let alert = DescriptionActionAlertController()
        alert.titleText = "This feature isn't available yet..."
        alert.descriptionText = "Thank you for testing Andante!"
        alert.actionText = "Okay"
        alert.action = {
            alert.close()
        }
        return alert
    }
    
    private let titleLabel = UILabel()
    private let textView = UITextView()
    private let actionButton = PushButton()
    
    public var titleText: String? {
        didSet {
            titleLabel.text = titleText
        }
    }
    
    public var descriptionText: String? {
        didSet {
            textView.text = descriptionText
        }
    }
    
    public var actionText: String? {
        didSet {
            actionButton.setTitle(actionText ?? "Confirm", color: Colors.white, font: Fonts.semibold.withSize(16))
        }
    }
    
    public var action: (()->Void)? {
        didSet {
            actionButton.action = {
                [weak self] in
                guard let self = self else { return }
                self.closeCompletion = {
                    [weak self] in
                    guard let self = self else { return }
                    self.action?()
                }
                self.close()
            }
        }
    }
    
    public var cancelAction: (()->Void)?
    private var shouldEvokeCancelAction = true
    
    convenience init(title: String?, description: String?, actionText: String?, action: (()->Void)?) {
        self.init(nibName: nil, bundle: nil)
        
        titleLabel.text = title
        textView.text = description
        actionButton.setTitle(actionText ?? "Confirm", color: Colors.white, font: Fonts.semibold.withSize(16))
        actionButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.shouldEvokeCancelAction = false
            self.closeCompletion = {
                action?()
            }
            self.close()
        }
        
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
        
        actionButton.backgroundColor = Colors.orange
        self.contentView.addSubview(actionButton)
        
    }
    
    override func viewDidLayoutSubviews() {
        
        let titleHeight = titleLabel.sizeThatFits(self.view.bounds.size).height
        let textHeight = textView.sizeThatFits(self.view.bounds.size).height
        let buttonHeight: CGFloat = 50
        
        self.contentHeight = titleHeight + textHeight + buttonHeight + 24 + 60
        
        super.viewDidLayoutSubviews()
        
        
        titleLabel.frame = CGRect(x: 0, y: contentView.safeAreaInsets.top + 24, width: contentView.bounds.width, height: titleHeight)
        textView.frame = CGRect(x: 0, y: titleLabel.frame.maxY, width: contentView.bounds.width, height: textHeight)
        
        actionButton.frame = CGRect(x: Constants.margin, y: self.contentView.bounds.maxY - buttonHeight - 22,
                                    width: contentView.bounds.width - Constants.margin*2,
                                    height: buttonHeight)
        actionButton.cornerRadius = 14
        
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if shouldEvokeCancelAction {
            print("Canceling")
            self.cancelAction?()
        }
    }
    
    
}



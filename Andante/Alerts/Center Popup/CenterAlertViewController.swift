
//
//  DescriptionActionCenterAlert.swift
//  Andante
//
//  Created by Miles Vinson on 9/24/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class CenterAlertViewController: CenterPickerViewController {
    
    public let labelGroup = TitleBodyGroup()
    
    private let actionButton = PushButton()
    private let cancelButton = PushButton()
    
    public var action: (()->Void)?
            
    convenience init(
        title: String? = nil,
        description: String? = nil,
        isDestructive: Bool = false,
        actionText: String = "Confirm",
        cancelText: String = "Cancel") {
        
        self.init()
        
        labelGroup.titleLabel.text = title
        labelGroup.textView.text = description
        
        actionButton.setTitle(
            actionText,
            color: isDestructive ? Colors.red : Colors.white,
            font: Fonts.semibold.withSize(17)
        )
        actionButton.backgroundColor = isDestructive ? Colors.red.withAlphaComponent(0.15) : Colors.orange
        
        cancelButton.setTitle(
            cancelText,
            color: Colors.text,
            font: Fonts.semibold.withSize(17)
        )
        
    }
            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        labelGroup.textAlignment = .center
        
        labelGroup.titleLabel.textColor = Colors.text
        labelGroup.titleLabel.font = Fonts.semibold.withSize(17)
        
        labelGroup.textView.textColor = Colors.lightText
        labelGroup.textView.font = Fonts.regular.withSize(16)
        
        labelGroup.padding = 1
        
        actionButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.closeAction = self.action
            self.close()
        }
        actionButton.cornerRadius = 14
        self.contentView.addSubview(actionButton)
        
        cancelButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.close()
        }
        cancelButton.backgroundColor = Colors.lightColor
        cancelButton.cornerRadius = 14
        self.contentView.addSubview(cancelButton)
        
        self.contentView.addSubview(labelGroup)

    }
    
    override func viewDidLayoutSubviews() {
        self.contentSize.width = 350

        let buttonHeight: CGFloat = 50
        let buttonSpacing: CGFloat = 14
           
        let height = labelGroup.sizeThatFits(CGSize(width: contentSize.width - Constants.margin*2, height: CGFloat.infinity)).height
        
        self.contentSize.height = height + 64 + buttonHeight*2 + buttonSpacing + 22
        
        super.viewDidLayoutSubviews()
        
        labelGroup.frame = CGRect(
            x: Constants.margin, y: 32,
            width: contentView.bounds.width - Constants.margin*2,
            height: height)
        
        actionButton.frame = CGRect(
            x: Constants.smallMargin, y: labelGroup.frame.maxY + 32,
            width: contentView.bounds.width - Constants.smallMargin*2,
            height: buttonHeight)
        
        cancelButton.frame = CGRect(
            x: Constants.smallMargin, y: actionButton.frame.maxY + buttonSpacing,
            width: contentView.bounds.width - Constants.smallMargin*2,
            height: buttonHeight)
    }
    
}

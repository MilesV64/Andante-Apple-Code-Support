//
//  DescriptionActionCenterAlert.swift
//  Andante
//
//  Created by Miles Vinson on 9/24/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class DescriptionActionCenterAlert: CancelConfirmCenterPickerViewController, UITextFieldDelegate {
    
    public let labelGroup = TitleBodyGroup()
            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        labelGroup.textAlignment = .center
        
        labelGroup.titleLabel.textColor = Colors.text
        labelGroup.titleLabel.font = Fonts.semibold.withSize(16)
        
        labelGroup.textView.textColor = Colors.lightText
        labelGroup.textView.font = Fonts.regular.withSize(15)
        
        labelGroup.padding = 1
        
        self.contentView.addSubview(labelGroup)

    }
    
    override func viewDidLayoutSubviews() {
           
        let height = labelGroup.sizeThatFits(self.contentView.bounds.insetBy(dx: Constants.margin, dy: 0).size).height
        labelGroup.frame = CGRect(
            x: Constants.margin, y: 20,
            width: contentView.bounds.width - Constants.margin*2,
            height: height)
        
        self.contentSize.height = height + 90
        
        super.viewDidLayoutSubviews()
    }
    
}

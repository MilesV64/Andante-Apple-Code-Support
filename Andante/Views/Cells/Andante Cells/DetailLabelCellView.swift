
//
//  DetailLabelCellView.swift
//  Andante
//
//  Created by Miles on 10/24/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class DetailLabelCellView: AndanteCellView {
    
    public let detailLabel = UILabel()
    
    override var accessoryView: UIView? {
        return self.detailLabel
    }
    
    public var detailText: String? {
        didSet {
            self.detailLabel.text = detailText
            self.detailLabel.sizeToFit()
            self.setNeedsLayout()
        }
    }
    
    override func sharedInit() {
        super.sharedInit()
        
        self.detailLabel.textColor = Colors.lightText
        self.detailLabel.font = Fonts.regular.withSize(16)
        
    }
    
}

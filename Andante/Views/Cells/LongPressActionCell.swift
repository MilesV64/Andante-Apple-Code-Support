//
//  LongPressActionCell.swift
//  Andante
//
//  Created by Miles Vinson on 7/21/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class LongPressActionCell: UITableViewCell {
    
    let longPressGesture = UILongPressGestureRecognizer()
    var longPressAction: (()->Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        longPressGesture.minimumPressDuration = 0.75
        longPressGesture.addTarget(self, action: #selector(handleLongPress))
        self.addGestureRecognizer(longPressGesture)
        
    }
    
    @objc private func handleLongPress() {
        self.longPressAction?()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
}


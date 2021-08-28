//
//  BackgroundLabel.swift
//  Andante
//
//  Created by Miles Vinson on 6/30/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class BackgroundLabel: UIView {
    
    public var label = UILabel()
    public var inset: UIEdgeInsets = .zero {
        didSet {
            setNeedsLayout()
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        self.addSubview(label)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.frame = self.bounds.inset(by: inset)
        
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let labelSize = label.sizeThatFits(size)
        return CGSize(
            width: labelSize.width + inset.left + inset.right,
            height: labelSize.height + inset.top + inset.bottom)
    }
}

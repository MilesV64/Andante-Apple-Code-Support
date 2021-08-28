//
//  ClippingShadowView.swift
//  Andante
//
//  Created by Miles Vinson on 4/10/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class ClippingShadowView: UIView {
    
    public var contentView = UIView()
    
    public var cornerRadius: CGFloat = 0 {
        didSet {
            contentView.roundCorners(cornerRadius)
            setShadowPath()
        }
    }
    
    override var backgroundColor: UIColor? {
        get {
            return contentView.backgroundColor
        }
        set {
            contentView.backgroundColor = newValue
            if newValue == UIColor.clear {
                super.backgroundColor = .clear
            }
        }
    }
    
    override func addSubview(_ view: UIView) {
        if view === contentView {
            super.addSubview(view)
        }
        else {
            contentView.addSubview(view)
        }
    }
    
    override func insertSubview(_ view: UIView, at index: Int) {
        contentView.insertSubview(view, at: index)
    }
    
    override func insertSubview(_ view: UIView, belowSubview siblingSubview: UIView) {
        contentView.insertSubview(view, belowSubview: siblingSubview)
    }
    
    override func insertSubview(_ view: UIView, aboveSubview siblingSubview: UIView) {
        contentView.insertSubview(view, aboveSubview: siblingSubview)
    }
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = .clear
        
        addSubview(contentView)
        contentView.clipsToBounds = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    private func setShadowPath() {
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.cornerRadius).cgPath
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.contextualFrame = self.bounds
        setShadowPath()
    }
}

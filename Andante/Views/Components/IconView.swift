//
//  IconView.swift
//  Andante
//
//  Created by Miles Vinson on 6/11/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class IconView: UIView {
    
    public var icon: UIImage? {
        didSet {
            imageView.image = icon
        }
    }
    
    public var iconColor: UIColor? {
        didSet {
            if let color = iconColor {
                imageView.setImageColor(color: color)
            }
        }
    }
    
    public var imageView = UIImageView()
    
    public var iconSize: CGSize? {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var iconInsets: UIEdgeInsets? {
        didSet {
            setNeedsLayout()
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        self.addSubview(imageView)
        
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let imgSize = imageView.sizeThatFits(size)
        let inset = iconInsets ?? .zero
        return CGSize(
            width: imgSize.width + inset.left + inset.right,
            height: imgSize.height + inset.top + inset.bottom)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let size = self.iconSize {
            imageView.bounds.size = size
            imageView.center = self.bounds.center
        }
        else if let inset = self.iconInsets {
            imageView.frame = self.bounds.inset(by: inset)
        }
        else {
            imageView.frame = self.bounds
        }
        
    }
}

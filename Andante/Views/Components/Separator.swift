//
//  Separator.swift
//  Andante
//
//  Created by Miles Vinson on 6/26/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class Separator: UIView {
    private let line = UIView()
    
    public var inset = UIEdgeInsets.zero
    
    enum Position {
        case top, bottom, middle
    }
    
    public var position: Position = .top {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var color: UIColor = Colors.separatorColor {
        didSet {
            self.line.backgroundColor = self.color
        }
    }
    
    convenience init(position: Separator.Position) {
        self.init()
        
        self.position = position
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.line.backgroundColor = self.color
        
        self.addSubview(line)
        
        self.backgroundColor = .clear
        
        self.isUserInteractionEnabled = false
    }
    
    override func addSubview(_ view: UIView) {
        super.addSubview(view)
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func insetToMargins() {
        self.inset = UIEdgeInsets(top: 0, left: Constants.margin, bottom: 0, right: Constants.margin)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let height: CGFloat = (1.0/UIScreen.main.scale)
        
        let inset = UIEdgeInsets(top: 0, left: self.inset.left, bottom: 0, right: self.inset.right)
        
        if position == .top {
            line.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: height).inset(by: inset)
        }
        else if position == .bottom {
            line.frame = CGRect(x: 0, y: self.bounds.height - height, width: self.bounds.width, height: height).inset(by: inset)
        }
        else {
            line.frame = CGRect(x: 0, y: self.bounds.midY - height/2, width: self.bounds.width, height: height).inset(by: inset)
        }
        
        
    }
}


//
//  CustomButton.swift
//  Andante
//
//  Created by Miles Vinson on 7/6/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class CustomButton: UIButton {
    
    public var action: (()->Void)? {
        didSet {
            self.addTarget(self, action: #selector(touchUp), for: .touchUpInside)
        }
    }
    
    public var highlightAction: ((Bool)->Void)?
    
    init() {
        super.init(frame: .zero)
        
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    public var touchMargin: CGFloat = 0

    override func point(inside point: CGPoint, with _: UIEvent?) -> Bool {
        let area = self.bounds.insetBy(dx: -touchMargin, dy: -touchMargin)
        return area.contains(point)
    }
    
    func initialize() {
        
    }
    
    override var isHighlighted: Bool {
        didSet {
            highlightAction?(isHighlighted)
        }
    }

    
    @objc func touchUp() {
        action?()
    }
    
    
}

extension UIButton {
    
    public func setTitle(_ title: String, color: UIColor, font: UIFont?) {
        self.setTitle(title, for: .normal)
        self.setTitleColor(color, for: .normal)
        self.titleLabel?.font = font
    }
    
    public func setRightImage(image: UIImage?, offset: CGFloat) {
        self.setImage(image, for: .normal)
        self.imageView?.translatesAutoresizingMaskIntoConstraints = false
        self.imageView?.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0.0).isActive = true
        self.imageView?.centerXAnchor.constraint(equalTo: self.trailingAnchor, constant: -offset).isActive = true
    }
    
}

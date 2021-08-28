//
//  Tintbutton.swift
//  Andante
//
//  Created by Miles Vinson on 7/14/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import UIKit

class TintButton: UIButton {
    private var dimView = UIView()
    
    private var handler: (() -> Void)?
    
    init() {
        super.init(frame: .zero)
        
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        dimView.frame = self.bounds
        dimView.layer.cornerRadius = self.layer.cornerRadius
        
        
    }
    
    public var touchMargin: CGFloat = 10
    
    override func point(inside point: CGPoint, with _: UIEvent?) -> Bool {
        let area = self.bounds.insetBy(dx: -touchMargin, dy: -touchMargin)
        return area.contains(point)
    }
    
    public var dimColor: UIColor? {
        get {
            return dimView.backgroundColor
        }
        set {
            dimView.backgroundColor = newValue
        }
    }
    
    func initialize() {
        self.insertSubview(dimView, at: 0)
        dimView.isUserInteractionEnabled = false
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        dimView.clipsToBounds = false
        dimView.alpha = 0
        
        self.adjustsImageWhenHighlighted = false

        
    }
    
    override var isHighlighted: Bool {
        didSet {
            setDim(isHighlighted)
        }
    }
    
    @objc func touchUp() {
        handler?()
    }
    
    public func setHandler(_ handler: (() -> Void)?) {
        self.handler = handler
        self.addTarget(self, action: #selector(touchUp), for: .touchUpInside)
    }
    
    public func setDim(_ dim: Bool) {
        if dim {
            dimView.alpha = 1
        }
        else {
            UIView.animate(withDuration: 0.15) {
                self.dimView.alpha = 0
            }
        }
    }
    
}


//
//  PracticeToolView.swift
//  Andante
//
//  Created by Miles Vinson on 7/25/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class PracticeToolView: UIView {
    
    static var Height: CGFloat {
        return isSmallScreen() ? 52 : 60
    }
    
    public let contentView = UIView()
    private let bgView = UIView()
    
    private var _isActive = false
    public var isActive: Bool {
        get {
            return _isActive
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        contentView.backgroundColor = PracticeColors.secondaryBackground
        contentView.roundCorners(10)
        contentView.clipsToBounds = true
        
        self.hide()
        
        bgView.backgroundColor = PracticeColors.secondaryBackground
        bgView.roundCorners(12)
        bgView.setShadow(radius: 3, yOffset: 6, opacity: 0.03)
        self.addSubview(bgView)
        
        bgView.addSubview(contentView)
    }
    
    public func show(delay: TimeInterval = 0) {
        _isActive = true
        UIView.animate(withDuration: 0.5, delay: delay, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.curveEaseOut], animations: {
            self.alpha = 1
            self.bgView.transform = .identity
        }, completion: nil)
    }
    
    public func hide(delay: TimeInterval = 0) {
        _isActive = false
        UIView.animate(withDuration: 0.5, delay: delay, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.curveEaseOut], animations: {
            self.alpha = 0
            self.bgView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }, completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bgView.bounds.size = self.bounds.insetBy(dx: Constants.margin, dy: 0).size
        bgView.center = self.bounds.center
        
        contentView.bounds.size = bgView.bounds.size
        contentView.center = bgView.bounds.center
        
    }
    
}

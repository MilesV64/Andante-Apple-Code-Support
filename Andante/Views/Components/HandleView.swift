//
//  HandleView.swift
//  Andante
//
//  Created by Miles Vinson on 7/6/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class HandleView: UIView {
    
    private let handleView = UIView()
    
    public var color: UIColor? {
        get { return handleView.backgroundColor }
        set { handleView.backgroundColor = newValue }
    }
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = .clear
        
        handleView.backgroundColor = Colors.lightBackground.withAlphaComponent(0.18)
        self.addSubview(handleView)
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 20)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
       
        let handleSize = CGSize(width: 36, height: 6)
        handleView.frame = CGRect(
            center: CGPoint(
                x: self.bounds.midX,
                y: 10),
            size: handleSize)
        handleView.roundCorners()
        
    }
}

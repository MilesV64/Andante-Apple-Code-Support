//
//  DoneToolbar.swift
//  Andante
//
//  Created by Miles Vinson on 6/28/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class DoneToolbar: UIView {
    
    private let doneButton = UIButton(type: .system)
    
    public var doneHandler: (()->Void)?
    
    struct HorizontalFrame {
        let x: CGFloat
        let width: CGFloat
    }
    public var horizontalFrame: HorizontalFrame? = nil {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var contentView = Separator()
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = .clear
        
        contentView.backgroundColor = Colors.foregroundColor
        contentView.position = .top
        self.addSubview(contentView)
        
        self.bounds.size.height = 44
        
        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(Colors.text, for: .normal)
        doneButton.titleLabel?.font = Fonts.semibold.withSize(17)
        
        doneButton.contentHorizontalAlignment = .right
        doneButton.titleEdgeInsets.right = Constants.margin
        
        doneButton.addTarget(self, action: #selector(didTapDone), for: .touchUpInside)
        
        contentView.addSubview(doneButton)
    }
    
    @objc func didTapDone() {
        doneHandler?()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let horizontalFrame = self.horizontalFrame {
            contentView.frame = CGRect(
                x: horizontalFrame.x, y: 0,
                width: horizontalFrame.width, height: bounds.maxY)
        }
        else {
            contentView.frame = self.bounds
        }
                
        doneButton.frame = CGRect(
            x: contentView.bounds.maxX - 80,
            y: 0,
            width: 80,
            height: self.bounds.height)
        
    }
}

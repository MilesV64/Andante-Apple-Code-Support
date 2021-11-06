//
//  CheckmarkCellView.swift
//  Andante
//
//  Created by Miles on 10/24/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit
import Lottie

// MARK: - Checkmark Cell

class CheckmarkCellView: AndanteCellView {
    
    override var accessoryView: UIView? {
        return self.checkmarkView
    }
    
    private(set) var isChecked: Bool = false
    
    private let checkmarkView = UIView()
    
    private let animationView = AnimationView(name: "checkmark")
    
    public func setChecked(_ checked: Bool, animated: Bool) {
        if checked {
            UIView.animate(withDuration: animated ? 0.2 : 1) {
                self.checkmarkView.backgroundColor = Colors.orange
            }
            
            if self.animationView.alpha != 1 {
                if animated {
                    self.animationView.currentTime = 0
                    self.animationView.alpha = 1
                    self.animationView.play()
                }
                else {
                    self.animationView.currentTime = 1
                    self.animationView.alpha = 1
                }
            }
            
        }
        else {
            self.checkmarkView.backgroundColor = Colors.lightColor
            self.animationView.alpha = 0
        }
    }
    
    override func sharedInit() {
        super.sharedInit()
        
        self.animationView.setValueProvider(
            ColorValueProvider(Color(r: 1, g: 1, b: 1, a: 1)),
            keypath: AnimationKeypath(keypath: "**.Stroke 1.Color"))
        self.animationView.setValueProvider(
            FloatValueProvider(50),
            keypath: AnimationKeypath(keypath: "**.Stroke 1.Stroke Width"))
        self.animationView.animationSpeed = 5
        self.animationView.alpha = 0
        
        self.checkmarkView.bounds.size = CGSize(24)
        self.checkmarkView.roundCorners(12, prefersContinuous: false)
        
        self.checkmarkView.addSubview(self.animationView)
        self.animationView.frame = self.checkmarkView.bounds.offsetBy(dx: -1, dy: 0)
        
    }
    
}


// MARK: - Checkmark Cell

class CheckmarkTableViewCell: UITableViewCell {
    
    let checkmarkCellView = CheckmarkCellView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = .clear
        self.addSubview(self.checkmarkCellView)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState]) {
            self.transform = highlighted ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
        } completion: { _ in
            //
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.checkmarkCellView.frame = self.bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


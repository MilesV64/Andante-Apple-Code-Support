//
//  CollapsedSessionView.swift
//  Andante
//
//  Created by Miles Vinson on 12/6/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

protocol CollapsedSessionViewDelegate: class {
    func collapsedSessionDidTapExpand()
}

class CollapsedSessionView: UIView {
    
    public weak var delegate: CollapsedSessionViewDelegate?
    
    public var practiceViewController: PracticeViewController?
    
    private let button = CustomButton()
    
    private var timerLabel = UILabel()
    
    init(_ practiceViewController: PracticeViewController) {
        super.init(frame: .zero)
        
        self.practiceViewController = practiceViewController
        
        self.backgroundColor = Colors.orange
        self.setShadow(radius: 6, yOffset: -2, opacity: 0.16)
        self.layer.shadowColor = Colors.barShadowColor.cgColor
        
        button.highlightAction = {
            [weak self] highlighted in
            guard let self = self else { return }
            
            if highlighted {
                UIView.animate(withDuration: 0.15) {
                    self.button.backgroundColor = UIColor.black.withAlphaComponent(0.12)
                }
            } else {
                UIView.animate(withDuration: 0.25) {
                    self.button.backgroundColor = .clear
                }
            }
            
        }
        
        button.action = {
            [weak self] in
            guard let self = self else { return }
            self.delegate?.collapsedSessionDidTapExpand()
        }

        addSubview(button)
        
        timerLabel.textColor = Colors.white
        timerLabel.alpha = practiceViewController.isTimerPaused ? 0.65 : 1
        timerLabel.text = practiceViewController.timerLabel.text
        timerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .semibold)
        timerLabel.isUserInteractionEnabled = false
        timerLabel.textAlignment = .center
        addSubview(timerLabel)
        
        practiceViewController.timerDidUpdateAction = {
            [weak self] string in
            guard let self = self else { return }
            self.timerLabel.text = string
        }
        
        timerLabel.transform = CGAffineTransform(scaleX: 3, y: 3).concatenating(CGAffineTransform(translationX: 0, y: 60))
        timerLabel.alpha = 0
        
        
    }
    
    public func animate(transform: Bool) {
        if transform {
            self.timerLabel.transform = .identity
        } else {
            UIView.performWithoutAnimation {
                self.timerLabel.transform = .identity
            }
        }
        
        self.timerLabel.alpha = 1
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layer.shadowColor = Colors.barShadowColor.cgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let mask = UIView(frame: CGRect(x: 0, y: -30, width: bounds.width, height: bounds.height + 30))
        mask.backgroundColor = .white
        self.mask = mask
        
        button.frame = self.bounds
        
        timerLabel.contextualFrame = CGRect(x: 0, y: 0, width: bounds.width, height: 54)
        
    }
}

//
//  PracticeToolButton.swift
//  Andante
//
//  Created by Miles Vinson on 7/25/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

protocol PracticeToolButtonDelegate: class {
    func didTapToolButton(_ button: PracticeToolButton)
}

class PracticeToolButton: UIView {
    
    public weak var delegate: PracticeToolButtonDelegate?
    
    enum State {
        case active, inactive
    }
    
    private var state: State = .inactive
    
    private let button = CustomButton()
    public var type: PracticeTool
        
    private var highlightedTransform = CGAffineTransform(scaleX: 0.88, y: 0.88)
    private var regularTransform = CGAffineTransform(scaleX: 0.95, y: 0.95)
    private var selectedTransform = CGAffineTransform.identity
    
    override func point(inside point: CGPoint, with _: UIEvent?) -> Bool {
        let area = self.bounds.insetBy(dx: -8, dy: -8)
        return area.contains(point)
    }
    
    init(_ type: PracticeTool) {
        self.type = type

        super.init(frame: .zero)
        
        button.backgroundColor = PracticeColors.unselectedToolButtonBG
        setButtonImage(false)
        
        button.tintColor = Colors.dynamicColor(light: Colors.white, dark: PracticeColors.text)
        button.adjustsImageWhenHighlighted = false
        button.touchMargin = 8
        
        button.imageEdgeInsets = UIEdgeInsets(13)
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        
        button.transform = regularTransform
        
        button.highlightAction = {
            [weak self] highlighted in
            guard let self = self else { return }
            
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.curveEaseInOut], animations: {
                
                self.setHighlighted(highlighted)
                
            }, completion: nil)
            
        }
        
        button.action = {
            [weak self] in
            guard let self = self else { return }
            self.delegate?.didTapToolButton(self)
        }
        
        self.addSubview(button)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setHighlighted(_ highlighted: Bool) {
        if highlighted {
            button.transform = highlightedTransform
        }
        else {
            if state == .active {
                button.transform = selectedTransform
            }
            else {
                button.transform = regularTransform
            }
        }
    }
    
    public func setState(_ state: PracticeToolButton.State) {
        self.state = state
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.curveEaseInOut], animations: {
            
            if state == .active {
                self.button.backgroundColor = PracticeColors.selectedToolButtonBG
                self.setButtonImage(true)
                self.button.tintColor = Colors.dynamicColor(light: Colors.text, dark: PracticeColors.background)
                self.button.transform = self.selectedTransform
            }
            else {
                self.button.backgroundColor = PracticeColors.unselectedToolButtonBG
                self.setButtonImage(false)
                self.button.tintColor = Colors.dynamicColor(light: Colors.white, dark: PracticeColors.text)
                self.button.transform = self.regularTransform
            }
            
        }, completion: nil)
        
    }
    
    private func setButtonImage(_ selected: Bool) {
        button.setImage(selected ? type.selectedIcon : type.icon, for: .normal)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        button.bounds.size = self.bounds.size
        button.center = self.bounds.center
        button.roundCorners(prefersContinuous: false)
        
    }
}

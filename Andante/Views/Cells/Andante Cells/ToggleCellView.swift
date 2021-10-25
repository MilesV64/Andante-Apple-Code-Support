//
//  ToggleCellView.swift
//  Andante
//
//  Created by Miles on 10/24/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

// MARK: - Toggle Cell

class ToggleCellView: AndanteCellView {
    
    private let toggle = UISwitch()
    
    public var toggleAction: ((Bool) -> ())?
    
    override var accessoryView: UIView? {
        return self.toggle
    }
    
    public var isOn: Bool = false {
        didSet {
            self.toggle.isOn = self.isOn
        }
    }
    
    override func sharedInit() {
        super.sharedInit()
        
        self.toggle.tintColor = Colors.green
        self.toggle.sizeToFit()
        
        self.button.highlightAction = nil
        self.button.action = nil
        
        self.toggle.addTarget(self, action: #selector(self.handleToggle), for: .valueChanged)
        
    }
    
    @objc private func handleToggle() {
        self.toggleAction?(self.toggle.isOn)
    }
    
}

//
//  BlurView.swift
//  Andante
//
//  Created by Miles Vinson on 8/7/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class BlurView: UIVisualEffectView {
    
    init() {
        super.init(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        self.contentView.backgroundColor = Colors.dynamicColor(light: Colors.barColor, dark: UIColor("#1E1D26").withAlphaComponent(0.75))
            
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
}

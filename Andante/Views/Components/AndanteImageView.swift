//
//  AndanteImageView.swift
//  Andante
//
//  Created by Miles Vinson on 7/15/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import UIKit
import Combine

class AndanteImageView: UIButton {
    
    public var alwaysTemplate: Bool = true
    
    public var image: UIImage? {
        didSet {
            guard image != oldValue else { return }
            if alwaysTemplate {
                self.setImage(image?.withRenderingMode(.alwaysTemplate), for: .normal)
            }
            else {
                self.setImage(image, for: .normal)
            }
        }
    }
    
    public var imageColor: UIColor {
        get {
            return self.tintColor
        }
        set {
            self.tintColor = newValue
        }
    }
    
    convenience init(image: UIImage?) {
        self.init()
        self.image = image
        self.setImage(image?.withRenderingMode(.alwaysTemplate), for: .normal)
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    private func initialize() {
        self.isEnabled = false
        self.adjustsImageWhenDisabled = false        
    }
    
}

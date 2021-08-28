//
//  GradientImageView.swift
//  Andante
//
//  Created by Miles Vinson on 9/20/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import UIKit

class GradientView: UIView {
    
    private let backgroundLayer = CAShapeLayer()
    private let gradientView = CAGradientLayer()
    
    public var startPoint: CGPoint {
        get {
            return gradientView.startPoint
        }
        set {
            gradientView.startPoint = newValue
        }
    }
    
    public var endPoint: CGPoint {
        get {
            return gradientView.endPoint
        }
        set {
            gradientView.endPoint = newValue
        }
    }
    
    enum GradientType {
        case lighter, darker, clear
    }
    
    public var gradientIntensity: CGFloat = 0.3 {
        didSet {
            reloadGradient()
        }
    }
    
    public var gradientType: GradientType = .lighter {
        didSet {
            switch self.gradientType {
            case .lighter:
                self.backgroundLayer.backgroundColor = UIColor.white.cgColor
            case .darker:
                self.backgroundLayer.backgroundColor = UIColor.black.cgColor
            case .clear:
                self.backgroundLayer.backgroundColor = UIColor.clear.cgColor
            }
        }
    }
    
    public var color: UIColor = Colors.lightBlue {
        didSet {
            reloadGradient()
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundLayer.backgroundColor = UIColor.white.cgColor
        self.layer.addSublayer(backgroundLayer)
        
        reloadGradient()
        
        gradientView.startPoint = CGPoint(x: 0.2, y: 0)
        gradientView.endPoint = CGPoint(x: 0.8, y: 1)
        
        self.layer.addSublayer(gradientView)
    }
    
    convenience init(color: UIColor) {
        self.init()
        
        self.color = color
        self.reloadGradient()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func reloadGradient() {
        if self.gradientType == .darker {
            gradientView.colors = [
            color.cgColor,
            color.cgColor.copy(alpha: 1 - gradientIntensity) ?? color.cgColor]
        }
        else {
            gradientView.colors = [
            color.cgColor.copy(alpha: 1 - gradientIntensity) ?? color.cgColor,
            color.cgColor]
            
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        gradientView.frame = self.bounds
        backgroundLayer.frame = self.bounds
        
        let mask = CAShapeLayer()
        let maskPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.layer.cornerRadius)
        mask.path = maskPath.cgPath
        
        let mask2 = CAShapeLayer()
        let maskPath2 = UIBezierPath(roundedRect: self.bounds.inset(by: UIEdgeInsets(0.5)), cornerRadius: self.layer.cornerRadius)
        mask2.path = maskPath2.cgPath
        
        gradientView.mask = mask

        backgroundLayer.mask = mask2
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        reloadGradient()
        
        
    }
    
}

class GradientImageView: UIView {
    
    private let gradientView = GradientView()
    private let imageView = AndanteImageView()
    
    public var image: UIImage? {
        didSet {
            imageView.image = image
            imageView.imageColor = Colors.white
        }
    }
    
    public var color: UIColor = Colors.lightBlue {
        didSet {
            gradientView.color = color
        }
    }

    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = .white
        
        gradientView.gradientIntensity = 0.2
        self.addSubview(gradientView)
        self.addSubview(imageView)
        
        self.setShadow(radius: 6, yOffset: 3, opacity: 0.08)
        
    }
    
    convenience init(image: UIImage?, color: UIColor) {
        self.init()
        
        self.image = image
        imageView.image = image
        imageView.imageColor = Colors.white
        
        self.color = color
        gradientView.color = color
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.roundCorners()
        
        gradientView.frame = self.bounds
        gradientView.roundCorners()
        
        imageView.frame = self.bounds
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}

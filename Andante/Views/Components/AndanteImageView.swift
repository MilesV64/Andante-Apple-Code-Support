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

class ProfileImageView: AndanteImageView {
    public var inset: CGFloat = 8 {
        didSet {
            self.imageEdgeInsets = UIEdgeInsets(inset)
        }
    }
    
    public var cornerRadius: CGFloat?
    
    init(profile: CDProfile? = nil) {
        super.init(frame: .zero)
        
        self.alwaysTemplate = false
        
        self.profile = profile
        
        self.backgroundColor = Colors.lightColor
        self.contentHorizontalAlignment = .fill
        self.contentVerticalAlignment = .fill
        self.imageEdgeInsets = UIEdgeInsets(inset)
        self.isUserInteractionEnabled = false
        
    }
    
    var cancellables = Set<AnyCancellable>()
    
    public var profile: CDProfile? {
        didSet {
            cancellables.removeAll()
            if let profile = profile {
                profile.publisher(for: \.iconName).sink(receiveValue: {
                    [weak self] (iconName) in
                    guard let self = self, let iconName = iconName else { return }
                    
                    self.iconName = iconName
                    self.setResponsiveImage(iconName)
                    
                }).store(in: &cancellables)
            }
            else {
                // all profiles
                self.image = nil
            }
        }
    }
    
    private var iconName: String = ""
    
    private func setResponsiveImage(_ name: String) {
        if bounds.inset(by: UIEdgeInsets(inset)).width <= 32 {
            self.image = UIImage(named: iconName + "-sm")
        } else {
            self.image = UIImage(named: iconName)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //print(iconName, imageView?.bounds)
        setResponsiveImage(iconName)
        self.roundCorners(cornerRadius)
        
    }
}

//
//  PopupOptionsView.swift
//  Andante
//
//  Created by Miles Vinson on 7/16/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class PopupOptionsView: Separator {
    
    public var isEnabled: Bool = true {
        didSet {
            options.forEach { $0.isOptionEnabled = isEnabled }
        }
    }
    
    private var options: [OptionButton] = []
    
    public static var height: CGFloat {
        return 76 + 16 + 8
    }
    
    init() {
        super.init(frame: .zero)
        
        self.position = .bottom
        self.color = Colors.barSeparator
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if options.count == 0 { return }
        
        let itemHeight: CGFloat = 76
        let spacing: CGFloat = 8
        let itemWidth = (bounds.width - CGFloat(options.count - 1)*spacing)/CGFloat(options.count)
        
        for (i, option) in options.enumerated() {
            option.frame = CGRect(
                x: CGFloat(i)*(itemWidth + spacing),
                y: 8, width: itemWidth, height: itemHeight)
        }        
        
    }
    
    public func addOption(title: String, iconName: String, destructive: Bool, action: (()->Void)?) {
        let option = OptionButton(title: title, iconName: iconName, destructive: destructive, action: action)
        option.isOptionEnabled = self.isEnabled
        self.addSubview(option)
        options.append(option)
    }
    
    public func option(at index: Int) -> OptionButton? {
        if index >= 0 && index < options.count {
            return options[index]
        }
        return nil
    }
    
    
    class OptionButton: PushButton {
        
        public var isOptionEnabled = true {
            didSet {
                if isOptionEnabled {
                    iconView.tintColor = color
                    label.textColor = color
                    backgroundColor = bgColor
                    self.isUserInteractionEnabled = true
                } else {
                    iconView.tintColor = Colors.extraLightText
                    label.textColor = Colors.extraLightText
                    backgroundColor = Colors.lightColor
                    self.isUserInteractionEnabled = false
                }
            }
        }
        
        private let bgColor: UIColor
        private let color: UIColor
        
        public let iconView = UIImageView()
        public let label = UILabel()
        
        init(title: String, iconName: String, destructive: Bool, action: (()->Void)?) {
            
            self.color = destructive ? Colors.red : Colors.text.withAlphaComponent(0.85)
            self.bgColor = destructive ? Colors.red.withAlphaComponent(0.1) : Colors.lightColor
            
            super.init()
            
            iconView.image = UIImage(name: iconName, pointSize: 18, weight: .medium)
            iconView.tintColor = color
            addSubview(iconView)
            
            label.text = title
            label.font = Fonts.medium.withSize(14)
            label.textColor = color
            addSubview(label)
            
            self.action = action
            
            self.backgroundColor = Colors.lightColor
            self.cornerRadius = 8
            
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            let iconBounds = CGSize(26)
            let spacing: CGFloat = 6
            
            iconView.sizeToFit()
            let labelSize = label.sizeThatFits(self.bounds.size)
            
            let totalHeight = iconBounds.height + labelSize.height + spacing
            
            let minY = bounds.midY - totalHeight/2 - 1
            
            iconView.center = CGPoint(
                x: bounds.midX,
                y: bounds.midY - totalHeight/2 + iconBounds.height/2)
            
            let labelCenter = CGPoint(
                x: bounds.midX,
                y: minY + iconBounds.height + spacing + label.bounds.height/2)
            
            label.frame = CGRect(center: labelCenter, size: labelSize).integral
            
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
}

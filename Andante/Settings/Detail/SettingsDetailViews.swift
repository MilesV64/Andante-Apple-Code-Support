//
//  SettingsDetailViews.swift
//  Andante
//
//  Created by Miles Vinson on 7/28/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class SettingsDetailItem: Separator {
    var height: CGFloat {
        return 0
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.position = .bottom
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}

class SettingsDetailView: SettingsDetailItem {
    
    override var height: CGFloat {
        return 56
    }
    
    public let button = CustomButton()
    public var action: (()->Void)? {
        didSet {
            button.action = self.action
        }
    }
    
    init(title: String, destructive: Bool = false) {
        super.init(frame: .zero)
                
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets.left = Constants.margin
        
        button.backgroundColor = .clear
        button.setTitle(title, for: .normal)
        button.setTitleColor(destructive ? Colors.red : Colors.text, for: .normal)
        button.titleLabel?.font = Fonts.medium.withSize(16)
        button.highlightAction = {
            [weak self] highlighted in
            guard let self = self else { return }
            
            if highlighted {
                self.button.backgroundColor = Colors.cellHighlightColor
            }
            else {
                UIView.animate(withDuration: 0.2) {
                    self.button.backgroundColor = .clear
                }
            }
        }
        
        self.addSubview(button)
                
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        button.frame = self.bounds
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
}

class SettingsDetailDetailView: SettingsDetailView {
    
    private let detailLabel = UILabel()
    
    public var detailText: String? {
        get {
            return detailLabel.text
        }
        set {
            detailLabel.text = newValue
        }
    }
        
    override init(title: String, destructive: Bool = false) {
        super.init(title: title)
        
        detailLabel.isUserInteractionEnabled = false
        detailLabel.textColor = Colors.lightText
        detailLabel.font = Fonts.regular.withSize(16)
        detailLabel.textAlignment = .right
        self.addSubview(detailLabel)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let titleLabel = button.titleLabel {
            let width = titleLabel.sizeThatFits(self.bounds.size).width
            let maxX = button.contentEdgeInsets.left + width
            detailLabel.frame = CGRect(
                from: CGPoint(x: maxX + 16, y: 0),
                to: CGPoint(x: self.bounds.maxX - Constants.margin, y: self.bounds.maxY))
        }
        
    }
}

class SettingsDetailTextFieldView: SettingsDetailView, UITextFieldDelegate {
    
    private let textField = UITextField()
    
    public var detailText: String? {
        didSet {
            textField.text = detailText
        }
    }
    
    public var textAction: ((String?)->Void)?
    
    override init(title: String, destructive: Bool = false) {
        super.init(title: title, destructive: destructive)
        
        textField.isUserInteractionEnabled = false
        textField.textColor = Colors.lightText
        textField.font = Fonts.regular.withSize(16)
        textField.delegate = self
        textField.textAlignment = .right
        textField.tintColor = Colors.purple
        textField.returnKeyType = .done
        textField.autocapitalizationType = .words
        button.addSubview(textField)
        
        button.action = {
            [weak self] in
            guard let self = self else { return }
            
            self.textField.isUserInteractionEnabled = true
            self.textField.becomeFirstResponder()
            
        }
        
    }
    
    public func stopEditing() {
        textField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.textAction?(textField.text)
        textField.isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let titleLabel = button.titleLabel {
            let width = titleLabel.sizeThatFits(self.bounds.size).width
            let maxX = button.contentEdgeInsets.left + width
            textField.frame = CGRect(
                from: CGPoint(x: maxX + 16, y: 0),
                to: CGPoint(x: self.bounds.maxX - Constants.margin, y: self.bounds.maxY))
        }
        
    }
    
    override var isFirstResponder: Bool {
        return textField.isFirstResponder
    }
}

class SettingsDetailProfileIconView: SettingsDetailView {
    
    private let iconView = ProfileImageView()
    
    public var profile: CDProfile? {
        didSet {
            iconView.profile = profile
        }
    }
    
    override init(title: String, destructive: Bool = false) {
        super.init(title: title, destructive: destructive)
        
        iconView.isUserInteractionEnabled = false
        iconView.backgroundColor = Colors.text.withAlphaComponent(0.05)
        iconView.inset = 6
        
        self.addSubview(iconView)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let buttonSize: CGFloat = 36
        iconView.frame = CGRect(
            x: self.bounds.maxX - Constants.smallMargin - buttonSize,
            y: self.bounds.midY - buttonSize/2,
            width: buttonSize, height: buttonSize)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class SettingsDetailGroupView: SettingsDetailItem {
    
    private let bgView = MaskedShadowView()
    private let contentView = UIView()
    
    override var height: CGFloat {
        return items.reduce(into: 0) { $0 += $1.height } + 12
    }
    
    public let items: [SettingsDetailItem]
    
    init(items: [SettingsDetailItem]) {
        self.items = items
        super.init(frame: .zero)
        
        self.color = .clear
        
        bgView.cornerRadius = 12
        self.addSubview(bgView)
        
        contentView.clipsToBounds = true
        contentView.roundCorners(12)
        bgView.addSubview(contentView)
        
        for item in items {
            contentView.addSubview(item)
            item.inset.left = Constants.margin
            item.inset.right = Constants.margin
        }
        
        items.last?.color = .clear
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bgView.frame = self.bounds.inset(
            by: UIEdgeInsets(t: 10, l: Constants.smallMargin, b: 2, r: Constants.smallMargin))
        
        contentView.frame = bgView.bounds
        
        var minY: CGFloat = 0
        for item in items {
            item.frame = CGRect(x: 0, y: minY, width: bgView.bounds.width, height: item.height)
            minY += item.height
        }
        
    }
}

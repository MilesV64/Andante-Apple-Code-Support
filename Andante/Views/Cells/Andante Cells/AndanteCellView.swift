//
//  AndanteCellView.swift
//  Andante
//
//  Created by Miles on 9/16/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit
import Combine

// MARK: - Andnate Cell View

class AndanteCellView: UIView {
    
    static let height: CGFloat = 60
    
    // - Views
    
    public let button = CustomButton()
    public let iconBG = UIView()
    public let iconView = UIImageView()
    public let label = UILabel()
    
    enum AccessoryStyle {
        case arrow
    }
        
    private(set) var accessoryView: UIView? {
        didSet {
            if oldValue != self.accessoryView {
                oldValue?.removeFromSuperview()
            }
            if let view = self.accessoryView {
                self.button.addSubview(view)
                self.setNeedsLayout()
            }
        }
    }
    
    private(set) var separator: Separator?
        
    
    // - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    
    // - Public Properties
    
    public var action: (() -> ())? {
        get { return self.button.action }
        set { self.button.action = newValue }
    }
    
    public var accessoryStyle: AccessoryStyle? {
        didSet {
            if self.accessoryStyle != oldValue {
                self.setAccessory()
            }
        }
    }

    public var imageSize: CGSize?
    public var margin: CGFloat = Constants.margin {
        didSet { self.setNeedsLayout() }
    }
    
    public var title: String? {
        get { return self.label.text }
        set { self.label.text = newValue }
    }
    
    public var alternateProfileTitle: String? {
        didSet {
            if self.profile != nil {
                self.label.text = self.alternateProfileTitle
            }
        }
    }
    
    public var icon: String? {
        didSet {
            if let icon = icon {
                self.iconView.image = UIImage(name: icon, pointSize: 17, weight: .medium)?.withRenderingMode(.alwaysTemplate)
                self.imageSize = nil
                self.profile = nil
            }
        }
    }
    
    public var image: UIImage? {
        didSet {
            self.iconView.image = image?.withRenderingMode(.alwaysTemplate)
            self.imageSize = nil
            self.profile = nil
        }
    }
    
    public var profile: CDProfile? {
        didSet {
            self.iconBG.backgroundColor = Colors.lightColor
            
            profile?.publisher(for: \.iconName, options: [.initial, .new]).sink {
                [weak self] iconName in
                guard let self = self, let iconName = iconName else { return }
                self.iconView.image = UIImage(named: iconName)
            }.store(in: &cancellables)
            
            profile?.publisher(for: \.name, options: [.initial, .new]).sink {
                [weak self] name in
                guard let self = self, let name = name else { return }
                if self.alternateProfileTitle == nil {
                    self.label.text = name
                }
            }.store(in: &cancellables)
            
            self.imageSize = CGSize(26)
        }
    }
    
    public var tintsTitleWithIconColor: Bool = false {
        didSet {
            if self.tintsTitleWithIconColor {
                self.label.textColor = self.iconBG.backgroundColor
            } else {
                self.label.textColor = Colors.text
            }
        }
    }
    
    
    // MARK: - Init
    
    init() {
        super.init(frame: .zero)
        
        self.sharedInit()
        
    }
    
    init(title: String, icon: String, iconColor: UIColor, tintsTitleWithIconColor: Bool = false) {
        super.init(frame: .zero)
        
        self.tintsTitleWithIconColor = tintsTitleWithIconColor
        
        self.label.text = title
        self.iconView.image = UIImage(name: icon, pointSize: 17, weight: .medium)?.withRenderingMode(.alwaysTemplate)
        self.iconView.tintColor = .white
        self.iconBG.backgroundColor = iconColor
        
        self.sharedInit()
        
    }
    
    init(title: String, icon: UIImage?, imageSize: CGSize? = nil, iconColor: UIColor, tintsTitleWithIconColor: Bool = false) {
        super.init(frame: .zero)
        
        self.tintsTitleWithIconColor = tintsTitleWithIconColor
        
        self.label.text = title
        self.iconView.image = icon?.withRenderingMode(.alwaysTemplate)
        self.iconView.tintColor = .white
        self.iconBG.backgroundColor = iconColor
        self.imageSize = imageSize
        
        self.sharedInit()
        
    }
    
    init(profile: CDProfile) {
        super.init(frame: .zero)
        
        self.iconBG.backgroundColor = Colors.lightColor
        
        profile.publisher(for: \.iconName, options: [.initial, .new]).sink {
            [weak self] iconName in
            guard let self = self, let iconName = iconName else { return }
            self.iconView.image = UIImage(named: iconName)
        }.store(in: &cancellables)
        
        profile.publisher(for: \.name, options: [.initial, .new]).sink {
            [weak self] name in
            guard let self = self, let name = name else { return }
            self.label.text = name
        }.store(in: &cancellables)
        
        self.imageSize = CGSize(26)
        
        self.sharedInit()
        
    }
    
    public func sharedInit() {
        
        self.iconBG.isUserInteractionEnabled = false
        self.iconView.isUserInteractionEnabled = false
        
        self.iconBG.roundCorners(8)
        self.iconBG.addSubview(self.iconView)
        self.button.addSubview(self.iconBG)
        
        if self.tintsTitleWithIconColor {
            self.label.textColor = iconBG.backgroundColor
        }
        else {
            self.label.textColor = Colors.text
        }
        
        self.label.font = Fonts.medium.withSize(17)
        self.button.addSubview(self.label)
        
        if let accessoryView = self.accessoryView {
            self.button.addSubview(accessoryView)
        }
        
        self.button.highlightAction = { [weak self] highlighted in
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState]) {
                self?.button.transform = highlighted ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
            } completion: { _ in
                //
            }
        }
        
        self.addSubview(self.button)
        
    }
    
    private func setAccessory() {
        guard let accessoryStyle = self.accessoryStyle else {
            self.accessoryView?.removeFromSuperview()
            return
        }
        
        switch accessoryStyle {
        case .arrow:
            let accessoryView = UIImageView(image: UIImage(name: "chevron.right", pointSize: 13, weight: .heavy)?.withRenderingMode(.alwaysTemplate))
            accessoryView.tintColor = Colors.extraLightText
            accessoryView.sizeToFit()
            self.accessoryView = accessoryView
            self.setNeedsLayout()
            
        }
        
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.button.contextualFrame = self.bounds
        
        self.iconBG.bounds.size = CGSize(width: 32, height: 32)
        self.iconBG.center = CGPoint(
            x: self.margin + self.iconBG.bounds.width / 2,
            y: self.bounds.midY)
        
        if let imageSize = self.imageSize {
            self.iconView.bounds.size = imageSize
        } else {
            self.iconView.sizeToFit()
        }
        self.iconView.center = self.iconBG.bounds.center
        
        var labelMaxX: CGFloat = self.bounds.maxX - margin
        
        if let accessory = self.accessoryView {
            accessory.center = CGPoint(
                x: self.bounds.maxX - margin - accessory.bounds.width / 2,
                y: self.bounds.midY)
            
            labelMaxX = accessory.contextualFrame.minX - 20
        }
        
        self.label.frame = CGRect(
            from: CGPoint(
                x: self.iconBG.contextualFrame.maxX + 14, y: 0
            ),
            to: CGPoint(
                x: labelMaxX, y: self.bounds.maxY
            )
        )
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


//MARK: - Andante TableView Cell

class AndanteTableViewCell: UITableViewCell {
    
    let andanteCellView = AndanteCellView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = .clear
        self.addSubview(self.andanteCellView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.andanteCellView.frame = self.bounds
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


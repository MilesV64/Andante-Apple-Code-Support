//
//  BaseStatView.swift
//  Andante
//
//  Created by Miles Vinson on 8/24/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class StatBackgroundView: MaskedShadowView {
    
    public let iconView = IconView()
    public let titleLabel = UILabel()
    
    public let titleSeparator = Separator()
    
    public let contentView = UIView()
    
    public var icon: UIImage? {
        didSet {
            iconView.icon = icon
            iconView.iconColor = Colors.white
        }
    }
    
    public var color: UIColor? {
        didSet {
            iconView.backgroundColor = color
        }
    }
    
    public var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    override init() {
        super.init()
        
        iconView.roundCorners(9)

        iconView.tintAdjustmentMode = .normal
        self.addSubview(iconView)
        
        titleLabel.textColor = Colors.text
        titleLabel.font = Fonts.semibold.withSize(17)
        self.addSubview(titleLabel)
        
        titleSeparator.insetToMargins()
        self.addSubview(titleSeparator)
        
        contentView.backgroundColor = .clear
        self.addSubview(contentView)
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        iconView.iconSize = CGSize(22)
        iconView.frame = CGRect(
            x: Constants.smallMargin,
            y: Constants.smallMargin,
            width: 36,
            height: 36).integral
        
        titleLabel.sizeToFit()
        titleLabel.frame.origin = CGPoint(
            x: iconView.frame.maxX + 14,
            y: iconView.frame.midY - titleLabel.bounds.height/2)
        
        titleSeparator.frame = CGRect(
            x: 0, y: iconView.frame.maxY + Constants.smallMargin,
            width: self.bounds.width, height: 1)
        
        contentView.frame = CGRect(
            from: CGPoint(x: 0, y: titleSeparator.frame.maxY),
            to: CGPoint(x: self.bounds.maxX, y: self.bounds.maxY))
        
    }
}

class BaseStatView: StatBackgroundView {
    
    public weak var delegate: UIViewController?
    
    public static let height: CGFloat = 340
    
    enum DataType {
        case recent, monthly, yearly, weekDay, timeOfDay, sessionLength
        
        var string: String {
            switch self {
            case .recent: return "Last 7 Days"
            case .monthly: return "This Month"
            case .yearly: return "This Year"
            case .weekDay: return "Day of the Week"
            case .timeOfDay: return "Time of Day"
            case .sessionLength: return "Session Length"
            }
        }
    }
    
    
    private let detailButton = DisclosureButton()
        
    private let detailSeparator = Separator()
    private let firstStatLabel = LabelGroup()
    private let secondStatLabel = LabelGroup()
    private let descriptionView = UITextView()
    
    public var detailText: String? {
        didSet {
            detailButton.title = detailText
            setNeedsLayout()
        }
    }
    
    public var descriptionText: String? {
        didSet {
            descriptionView.text = descriptionText
            setNeedsLayout()
        }
    }
    
    override init() {
        super.init()
        
        self.addSubview(detailButton)
        detailButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.didTapDetailButton()
        }
        
        detailSeparator.insetToMargins()
        self.addSubview(detailSeparator)
        
        for label in [firstStatLabel, secondStatLabel] {
            label.titleLabel.textColor = Colors.text
            label.titleLabel.font = Fonts.semibold.withSize(19)
            label.detailLabel.textColor = Colors.lightText
            label.detailLabel.font = Fonts.regular.withSize(15)
            label.padding = 1
            self.addSubview(label)
        }
        
        descriptionView.textColor = Colors.lightText
        descriptionView.font = Fonts.regular.withSize(16)
        descriptionView.isUserInteractionEnabled = false
        descriptionView.backgroundColor = .clear
        descriptionView.textContainerInset.left = Constants.margin - 4
        descriptionView.textContainerInset.right = Constants.margin - 4
        self.addSubview(descriptionView)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public func didTapDetailButton() {
        
    }
    
    public func setFirstStatLabel(title: String, detail: String) {
        firstStatLabel.titleLabel.text = title
        firstStatLabel.detailLabel.text = detail
        setNeedsLayout()
    }
    
    public func setSecondStatLabel(title: String, detail: String) {
        secondStatLabel.titleLabel.text = title
        secondStatLabel.detailLabel.text = detail
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        detailButton.sizeToFit()
        detailButton.frame.origin = CGPoint(
            x: self.bounds.maxX - detailButton.bounds.width,
            y: iconView.frame.midY - detailButton.bounds.height/2)

        contentView.frame = CGRect(
            from: CGPoint(x: 0, y: titleSeparator.frame.maxY),
            to: CGPoint(x: self.bounds.maxX, y: self.bounds.maxY - 80))
        
        detailSeparator.frame = CGRect(
            x: 0, y: contentView.frame.maxY + 4,
            width: self.bounds.width, height: 1)
        
        layoutStatLabels()
        
    }
    
    private func layoutStatLabels() {
        firstStatLabel.sizeToFit()
        secondStatLabel.sizeToFit()
        
        firstStatLabel.frame.origin = CGPoint(
            x: Constants.margin,
            y: detailSeparator.frame.maxY + 14)
        
        secondStatLabel.frame.origin = CGPoint(
            x: firstStatLabel.frame.maxX + Constants.margin*2,
            y: detailSeparator.frame.maxY + 14)
        
        descriptionView.frame = CGRect(
            x: 0, y: detailSeparator.frame.maxY + 6,
            width: self.bounds.width, height: self.bounds.height - (detailSeparator.frame.maxY + 6))
    }
    
    
}

fileprivate class DisclosureButton: UIView {
    
    private let button = CustomButton()
    
    public var title: String? {
        didSet {
            label.text = title
        }
    }
    
    private let label = UILabel()
    private let arrow = UIImageView()
    
    public var action: (()->Void)? {
        didSet {
            button.action = action
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        label.textColor = Colors.lightText
        label.font = Fonts.regular.withSize(16)
        label.textAlignment = .right
        button.addSubview(label)
        
        arrow.image = UIImage(name: "chevron.down", pointSize: 15, weight: .regular)
        arrow.setImageColor(color: Colors.lightText)
        button.addSubview(arrow)
        
        button.highlightAction = {
            [weak self] highlighted in
            guard let self = self else { return }
            if highlighted {
                self.alpha = 0.25
            }
            else {
                UIView.animate(withDuration: 0.35) {
                    self.alpha = 1
                }
            }
        }
        
        self.addSubview(button)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let labelSize = label.sizeThatFits(size)
        let iconSize = arrow.sizeThatFits(size)
        return CGSize(
            width: labelSize.width + iconSize.width + Constants.smallMargin*2 + 6,
            height: iconSize.height + 24)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        button.frame = self.bounds
        
        arrow.sizeToFit()
        arrow.frame.origin = CGPoint(
            x: self.bounds.maxX - Constants.smallMargin - arrow.bounds.width,
            y: self.bounds.midY - arrow.bounds.height/2)
        
        label.frame = CGRect(
            from: CGPoint(x: Constants.smallMargin, y: 0),
            to: CGPoint(x: arrow.frame.minX - 6, y: self.bounds.maxY))
        
    }
}

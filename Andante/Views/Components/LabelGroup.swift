//
//  LabelGroup.swift
//  Andante
//
//  Created by Miles Vinson on 8/2/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import UIKit

class LabelGroup: UIView {
    
    public let titleLabel = UILabel()
    public let detailLabel = UILabel()
    
    public var padding: CGFloat = -1 {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var textAlignment: NSTextAlignment = .left {
        didSet {
            titleLabel.textAlignment = textAlignment
            detailLabel.textAlignment = textAlignment
        }
    }
    
    
    init() {
        super.init(frame: .zero)
        
        titleLabel.textColor = Colors.text
        titleLabel.font = Fonts.semibold.withSize(20)
        titleLabel.baselineAdjustment = .alignCenters
        self.addSubview(titleLabel)
        
        detailLabel.textColor = Colors.lightText
        detailLabel.font = Fonts.semibold.withSize(16)
        detailLabel.baselineAdjustment = .alignCenters
        self.addSubview(detailLabel)
        
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let titleSize = titleLabel.sizeThatFits(size)
        let detailSize = detailLabel.sizeThatFits(size)
        
        return CGSize(width: max(titleSize.width, detailSize.width),
                      height: titleSize.height + detailSize.height + padding)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let titleSize = titleLabel.sizeThatFits(self.bounds.size)
        let detailSize = detailLabel.sizeThatFits(self.bounds.size)
        
        let combinedHeight = titleSize.height + detailSize.height + padding
        let minY = self.bounds.midY - combinedHeight/2
        
        titleLabel.contextualFrame = CGRect(x: 0,
                                  y: minY,
                                  width: self.bounds.width,
                                  height: titleSize.height).integral
        
        detailLabel.contextualFrame = CGRect(x: 0,
                                   y: titleLabel.contextualFrame.maxY + padding,
                                   width: self.bounds.width,
                                   height: detailSize.height).integral
        
    }
}

class TitleBodyGroup: UIView {
    
    public let titleLabel = UILabel()
    
    public let textView = UITextView()
    
    public var margin: CGFloat = Constants.margin
    
    public var padding: CGFloat = 1 {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var textAlignment: NSTextAlignment = .left {
        didSet {
            titleLabel.textAlignment = textAlignment
            textView.textAlignment = textAlignment
        }
    }
    
    
    init() {
        super.init(frame: .zero)
        
        titleLabel.textColor = Colors.text
        titleLabel.font = Fonts.semibold.withSize(17)
        titleLabel.baselineAdjustment = .alignCenters
        self.addSubview(titleLabel)
        
        textView.textColor = Colors.lightText
        textView.font = Fonts.regular.withSize(16)
        textView.textContainerInset.left = Constants.margin - 5
        textView.textContainerInset.right = Constants.margin - 5
        textView.isScrollEnabled = false
        textView.isUserInteractionEnabled = false
        textView.backgroundColor = .clear
        self.addSubview(textView)
        
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let titleSize = titleLabel.text != nil ? titleLabel.sizeThatFits(size) : .zero
        let detailSize = textView.hasText ? textView.sizeThatFits(size) : .zero
        let padding = textView.hasText ? self.padding : 0
        
        return CGSize(width: max(titleSize.width, detailSize.width),
                      height: titleSize.height + detailSize.height + padding)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let titleSize = titleLabel.text != nil ? titleLabel.sizeThatFits(self.bounds.size) : .zero
        let detailSize = textView.hasText ? textView.sizeThatFits(self.bounds.size) : .zero
        let padding = (titleLabel.text != nil && textView.hasText) ? self.padding : 0
        
        let combinedHeight = titleSize.height + detailSize.height + padding
        let minY = self.bounds.midY - combinedHeight/2
        
        titleLabel.frame = CGRect(x: margin,
                                  y: minY,
                                  width: self.bounds.width - margin*2,
                                  height: titleSize.height).integral
        
        textView.frame = CGRect(x: 0,
                                y: titleLabel.frame.maxY + padding,
                                width: self.bounds.width,
                                height: detailSize.height).integral
        
    }
}

class TextViewGroup: UIView {
    
    public let titleTextView = UITextView()
    
    public let detailTextView = UITextView()
    
    public var padding: CGFloat = 1 {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var textAlignment: NSTextAlignment = .left {
        didSet {
            titleTextView.textAlignment = textAlignment
            detailTextView.textAlignment = textAlignment
        }
    }
    
    
    init() {
        super.init(frame: .zero)

        titleTextView.textColor = Colors.text
        titleTextView.font = Fonts.semibold.withSize(17)
        titleTextView.textContainerInset.left = Constants.margin
        titleTextView.textContainerInset.right = Constants.margin
        titleTextView.isScrollEnabled = false
        titleTextView.isUserInteractionEnabled = false
        titleTextView.backgroundColor = .clear
        self.addSubview(titleTextView)
        
        detailTextView.textColor = Colors.lightText
        detailTextView.font = Fonts.regular.withSize(16)
        detailTextView.textContainerInset.left = Constants.margin
        detailTextView.textContainerInset.right = Constants.margin
        detailTextView.isScrollEnabled = false
        detailTextView.isUserInteractionEnabled = false
        detailTextView.backgroundColor = .clear
        self.addSubview(detailTextView)
        
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let titleSize = titleTextView.text != nil ? titleTextView.sizeThatFits(size) : .zero
        let detailSize = detailTextView.hasText ? detailTextView.sizeThatFits(size) : .zero
        let padding = detailTextView.hasText ? self.padding : 0
        
        return CGSize(width: max(titleSize.width, detailSize.width),
                      height: titleSize.height + detailSize.height + padding)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let titleSize = titleTextView.text != nil ? titleTextView.sizeThatFits(self.bounds.size).height - 5 : .zero
        let detailSize = detailTextView.hasText ? detailTextView.sizeThatFits(self.bounds.size).height - 5 : .zero
        let padding = (titleTextView.text != nil && detailTextView.hasText) ? self.padding : 0
        
        let combinedHeight = titleSize + detailSize + padding
        let minY = self.bounds.midY - combinedHeight/2
        
        titleTextView.frame = CGRect(x: Constants.margin,
                                  y: minY,
                                  width: self.bounds.width - Constants.margin*2,
                                  height: titleSize).integral
        
        detailTextView.frame = CGRect(x: 0,
                                y: titleTextView.frame.maxY + padding,
                                width: self.bounds.width,
                                height: detailSize).integral
        
    }
}

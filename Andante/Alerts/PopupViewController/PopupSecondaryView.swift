//
//  PopupSecondaryView.swift
//  Andante
//
//  Created by Miles Vinson on 2/20/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class PopupContentView: UIView {
    
    public weak var popupViewController: TransitionPopupViewController?
      
    public func preferredHeight(for width: CGFloat) -> CGFloat {
        return 0
    }
    
    public func didTransition(_ popupViewController: TransitionPopupViewController) {
        
    }
    
    public func willDissapear() {
        
    }
    
    public func didDissapear() {
        
    }
    
    public func willDrag() {
        
    }
    
    private var _safeAreaInsets: UIEdgeInsets?
    public func setSafeArea(_ inset: UIEdgeInsets?) {
        _safeAreaInsets = inset
    }
    override public var safeAreaInsets: UIEdgeInsets {
        return _safeAreaInsets ?? super.safeAreaInsets
    }
    
    init() {
        super.init(frame: .zero)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class PopupSecondaryViewHeader: Separator {
    
    public static var height: CGFloat = 48
    
    private var label = UILabel()
    private var cancelButton = Button()
        
    public var cancelButtonOffset: CGFloat = 0
    
    init(title: String) {
        super.init(frame: .zero)
        
        self.position = .bottom
        self.insetToMargins()
        
        label.text = title
        label.font = Fonts.bold.withSize(17)
        label.textColor = Colors.text
        addSubview(label)
        
        cancelButton.tintColor = Colors.extraLightText
        cancelButton.action = {
            [weak self] in
            guard let self = self else { return }
            if let superview = self.superview as? PopupContentView {
                superview.popupViewController?.popSecondaryView()
            }
        }
        cancelButton.setImage(UIImage(name: "xmark.circle.fill", pointSize: 20, weight: .bold), for: .normal)
        cancelButton.contentHorizontalAlignment = .right
        cancelButton.contentEdgeInsets.right = Constants.margin
        cancelButton.contentEdgeInsets.top = 6
        addSubview(cancelButton)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.frame = self.bounds.inset(
            by: UIEdgeInsets(top: 6, left: self.inset.left, bottom: 8, right: self.inset.right))
        
        cancelButton.frame = CGRect(
            x: bounds.maxX - 70,
            y: 0,
            width: 70,
            height: bounds.height - 8 - self.cancelButtonOffset)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class PopupActionButtonView: Separator {
    
    public static var height: CGFloat = 92
    
    private let button = PushButton()
    
    public var action: (()->())? {
        didSet {
            button.action = action
        }
    }
    
    public var isEnabled = true {
        didSet {
            setButton()
        }
    }
    
    private let title: String
    
    init(_ title: String) {
        self.title = title
        
        super.init(frame: .zero)
        
        self.insetToMargins()
        self.position = .top
        
        setButton()
        
        button.cornerRadius = 12
        
        addSubview(button)
    }
    
    private func setButton() {
        if isEnabled {
            button.backgroundColor = Colors.orange
            button.setTitle(title, color: Colors.white, font: Fonts.medium.withSize(17))
            button.isUserInteractionEnabled = true
        }
        else {
            button.backgroundColor = Colors.lightColor
            button.setTitle(title, color: Colors.extraLightText, font: Fonts.medium.withSize(17))
            button.isUserInteractionEnabled = false
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        button.frame = CGRect(
            x: Constants.smallMargin,
            y: 18,
            width: bounds.width - Constants.smallMargin*2,
            height: 52)
    
    }
}

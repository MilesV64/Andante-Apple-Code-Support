//
//  TextEditorToolbar.swift
//  Andante
//
//  Created by Miles Vinson on 4/4/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

protocol TextEditorToolbarDelegate: class {
    func toolbarDidSelectTextStyle()
    func toolbarDidSelectPhotoLibrary()
    func toolbarDidSelectCamera()
    func toolbarDidSelectSketch()
    func toolbarDidSelectDone()
}

class TextEditorToolbar: UIView {
    
    public weak var delegate: TextEditorToolbarDelegate?
    
    private let toolbarView = Separator(position: .top)
        
    private let doneButton = PushButton()
    
    private let textStyleButton = Button()
    private let libraryButton = Button()
    private let cameraButton = Button()
    private let sketchButton = Button()
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        toolbarView.setShadow(radius: 8, yOffset: 0, opacity: 0.06, color: Colors.barShadowColor)
    }
        
    init() {
        super.init(frame: .zero)
        
        self.clipsToBounds = false
        toolbarView.clipsToBounds = false
        
        toolbarView.setShadow(radius: 8, yOffset: 0, opacity: 0.06, color: Colors.barShadowColor)
        toolbarView.backgroundColor = Colors.elevatedForeground
        addSubview(toolbarView)
                
        doneButton.setTitle("Done", color: Colors.foregroundColor, font: Fonts.semibold.withSize(15))
        doneButton.backgroundColor = Colors.text
        doneButton.addTarget(self, action: #selector(didTapDone), for: .touchUpInside)
        toolbarView.addSubview(doneButton)
        
        textStyleButton.setImage(UIImage(name: "textformat", pointSize: 18, weight: .medium), for: .normal)
        textStyleButton.tintColor = Colors.text
        textStyleButton.addTarget(self, action: #selector(didTapTextStyle), for: .touchUpInside)
        toolbarView.addSubview(textStyleButton)
        
        libraryButton.setImage(UIImage(name: "photo", pointSize: 18, weight: .medium), for: .normal)
        libraryButton.tintColor = Colors.text
        libraryButton.addTarget(self, action: #selector(didTapLibrary), for: .touchUpInside)
        toolbarView.addSubview(libraryButton)
        
        cameraButton.setImage(UIImage(name: "camera", pointSize: 18, weight: .medium), for: .normal)
        cameraButton.tintColor = Colors.text
        cameraButton.addTarget(self, action: #selector(didTapCamera), for: .touchUpInside)
        toolbarView.addSubview(cameraButton)
        
        sketchButton.setImage(UIImage(name: "pencil.tip", pointSize: 18, weight: .medium), for: .normal)
        sketchButton.tintColor = Colors.text
        sketchButton.addTarget(self, action: #selector(didTapSketch), for: .touchUpInside)
        toolbarView.addSubview(sketchButton)
        
    }
    
    @objc func didTapTextStyle() {
        delegate?.toolbarDidSelectTextStyle()
    }
    
    @objc func didTapLibrary() {
        delegate?.toolbarDidSelectPhotoLibrary()
    }
    
    @objc func didTapCamera() {
        delegate?.toolbarDidSelectCamera()
    }
    
    @objc func didTapSketch() {
        delegate?.toolbarDidSelectSketch()
    }
    
    @objc func didTapDone() {
        delegate?.toolbarDidSelectDone()
    }
    
    public func hide(animated: Bool = true) {
        self.isUserInteractionEnabled = false
        UIView.animate(withDuration: animated ? 0.2 : 0) {
            self.toolbarView.alpha = 0
            self.toolbarView.frame.origin.y = self.bounds.maxY
        }
    }
    
    public func show(animated: Bool = true, delay: Bool = false) {
        self.isUserInteractionEnabled = true
        UIView.animate(withDuration: animated ? 0.4 : 0, delay: delay ? 0.05 : 0, usingSpringWithDamping: 0.92, initialSpringVelocity: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
            
            self.toolbarView.alpha = 1
            self.toolbarView.frame.origin.y = 0
            
        }, completion: nil)

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        toolbarView.frame = CGRect(
            x: 0, y: 0,
            width: bounds.width,
            height: bounds.height - safeAreaInsets.bottom)
        
        toolbarView.layer.shadowPath = UIBezierPath(roundedRect: toolbarView.bounds, cornerRadius: 0).cgPath
                        
        doneButton.frame = CGRect(
            x: toolbarView.bounds.maxX - 12 - 72,
            y: toolbarView.bounds.midY - 16,
            width: 72, height: 32)
        doneButton.cornerRadius = 16
        
        let buttonWidth = (self.bounds.width - doneButton.bounds.width - 20)/4
        for (i, button) in [textStyleButton, libraryButton, cameraButton, sketchButton].enumerated() {
            button.frame = CGRect(
                x: CGFloat(i)*buttonWidth, y: 0,
                width: buttonWidth,
                height: toolbarView.bounds.height)
        }
        
    }
}

class ToolbarPickerView: UIView {
    
    private let bgView = ClippingShadowView()
    private let contentView = UIView()
    private let handleView = HandleView()
    private let panGesture = UIPanGestureRecognizer()
    
    private var options: [OptionButton] = []
    
    private let scrollView = CancelTouchScrollView()
    
    public var willClose: (()->())?
    public var didClose: (()->())?
    
    init() {
        super.init(frame: .zero)
        
        addSubview(bgView)
        
        bgView.backgroundColor = Colors.elevatedForeground
        bgView.setShadow(radius: 16, yOffset: 12, opacity: 0.38, color: Colors.darkerBarShadow)
        bgView.cornerRadius = 10
        
        contentView.clipsToBounds = true
        contentView.roundCorners(8)
        bgView.addSubview(contentView)
        
        bgView.addSubview(handleView)
        
        bgView.addGestureRecognizer(panGesture)
        panGesture.addTarget(self, action: #selector(handlePan))
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        bgView.setShadow(radius: 16, yOffset: 12, opacity: 0.38, color: Colors.darkerBarShadow)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public var useWideOptions = false
    
    public func addOption(title: String, icon: String, isSelected: Bool = false, action: (()->())?) {
        let option = OptionButton()
        
        option.title = title
        
        if let image = UIImage(name: icon, pointSize: 21, weight: .regular) {
            option.icon = image
        }
        else {
            option.icon = UIImage(named: icon)
        }
        
        option.isActive = isSelected
        
        option.action = {
            [weak self] in
            guard let self = self else { return }
            
            for otherOption in self.options {
                if otherOption === option {
                    otherOption.isActive = true
                }
                else {
                    otherOption.isActive = false
                }
            }
            
            action?()
            self.close()
            
        }
        
        
        contentView.addSubview(option)
        options.append(option)
    }
    
    public func close() {
        willClose?()
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            self.bgView.contextualFrame.origin.y = self.bounds.height + 20
            self.bgView.alpha = 0
        }, completion: { complete in
            self.didClose?()
        })
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if panGesture.state == .possible {
            bgView.contextualFrame = self.bounds
        }
             
        handleView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 20)
        
        contentView.frame = self.bounds.inset(by: UIEdgeInsets(t: 20, l: 8, b: 8, r: 8))
        
        let optionSize = contentView.bounds.width / CGFloat(options.count)
        
        for (i, option) in options.enumerated() {
            option.frame = CGRect(
                x: CGFloat(i) * optionSize, y: 0,
                width: optionSize,
                height: contentView.bounds.height)
            
        }
        
    }
    
    @objc func handlePan() {
        
        if panGesture.state == .began {
            
        }
        else if panGesture.state == .changed {
            var translation = panGesture.translation(in: self).y
            if translation < 0 {
                translation = easeTranslation(translation, min: 0, max: 0)
                bgView.contextualFrame = CGRect(x: 0, y: translation, width: bounds.width, height: bounds.height)
            }
            else {
                let phase = translation / (bounds.height)
                
                contentView.alpha = 1 - phase
                bgView.contextualFrame = CGRect(x: 0, y: translation, width: bounds.width, height: bounds.height)
                
                if translation > bounds.height + 30 {
                    panGesture.isEnabled = false
                    panGesture.isEnabled = true
                }
            }
            
        }
        else {
            let translation = panGesture.translation(in: self).y
            let velocity = panGesture.velocity(in: self).y
            
            if (translation > bgView.bounds.height / 2) || velocity > 40 {
                let target = self.bounds.height + 20
                let actualVelocity = velocity / max(0.01, target - bgView.contextualFrame.origin.y)
                
                willClose?()
                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: actualVelocity, options: .curveLinear, animations: {
                    self.bgView.contextualFrame.origin.y = target
                    self.bgView.alpha = 0
                }, completion: { complete in
                    self.didClose?()
                })
            }
            else {
                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                    self.bgView.contextualFrame.origin.y = 0
                    self.bgView.alpha = 1
                    self.contentView.alpha = 1
                }, completion: { complete in })
            }
        }
        
    }
    
    private func getGesturePhase(_ gesture: UIPanGestureRecognizer) -> CGFloat {
        return bgView.contextualFrame.origin.y / (bgView.bounds.height + 20)
    }
    
    
    class OptionButton: PushButton {
        
        private let iconView = UIImageView()
        private let label = UILabel()
        
        public var isActive: Bool = false {
            didSet {
                if isActive {
                    self.backgroundColor = Colors.orange
                    self.buttonView.setShadow(radius: 4, yOffset: 2, opacity: 0.08)
                    self.iconView.tintColor = Colors.white
                    self.label.textColor = Colors.white.withAlphaComponent(0.75)
                }
                else {
                    self.backgroundColor = Colors.orange.withAlphaComponent(0)
                    self.iconView.tintColor = Colors.text
                    self.buttonView.setShadow(radius: 6, yOffset: 3, opacity: 0)
                    self.label.textColor = Colors.extraLightText
                }
            }
        }
        
        public var title: String? {
            get { return label.text }
            set { label.text = newValue }
        }
        
        public var icon: UIImage? {
            get { return iconView.image }
            set { iconView.image = newValue }
        }
        
        override init() {
            super.init()
                        
            addSubview(iconView)

            label.font = Fonts.regular.withSize(12)
            addSubview(label)
            
            self.cornerRadius = 8
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            if let image = iconView.image {
                iconView.bounds.size = image.size
                iconView.center = CGPoint(x: bounds.midX, y: bounds.midY - 11)
            }
            
            label.sizeToFit()
            label.center = CGPoint(x: bounds.midX, y: bounds.midY + 15)
            
        }
        
    }
    
}

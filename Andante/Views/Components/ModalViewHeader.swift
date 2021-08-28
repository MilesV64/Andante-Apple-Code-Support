//
//  ModalViewHeader.swift
//  Andante
//
//  Created by Miles Vinson on 9/22/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import UIKit

class ModalViewHeader: UIView {
        
    private let headerLabel = UILabel()
    
    private let doneButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    private let headerSeparator = Separator(position: .bottom)
    private let handleView = HandleView()
    
    public var doneButtonAction: (()->Void)?
    
    public var cancelButtonAction: (()->Void)?
    
    public var extraInset: UIEdgeInsets = .zero
    
    public var title: String? {
        get {
            return headerLabel.text
        }
        set {
            headerLabel.text = newValue
        }
    }
    
    public var doneButtonText: String? {
        get {
            return doneButton.title(for: .normal)
        }
        set {
            doneButton.setTitle(newValue, for: .normal)
        }
    }
    
    public var showsDoneButton: Bool {
        get {
            return doneButton.alpha == 0
        }
        set {
            doneButton.alpha = newValue ? 1 : 0
        }
    }
    
    public var cancelButtonText: String? {
        get {
            return cancelButton.title(for: .normal)
        }
        set {
            cancelButton.setTitle(newValue, for: .normal)
        }
    }
    
    public var showsCancelButton: Bool {
        get {
            return cancelButton.alpha == 0
        }
        set {
            cancelButton.alpha = newValue ? 1 : 0
        }
    }
    
    public var showsSeparator: Bool {
        get {
            return headerSeparator.isHidden == false
        }
        set {
            headerSeparator.isHidden = !newValue
        }
    }
    
    public var showsHandle: Bool {
        get {
            return handleView.isHidden == false
        }
        set {
            handleView.isHidden = !newValue
        }
    }
    
    public func setDoneButtonEnabled(_ enabled: Bool) {
        doneButton.isEnabled = enabled
    }
    
    convenience init(title: String) {
        self.init()
        
        self.title = title
        headerLabel.text = title
    }
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = Colors.barColor
                
        headerSeparator.color = Colors.barSeparator
        self.addSubview(headerSeparator)
        
        self.addSubview(handleView)
                
        headerLabel.textColor = Colors.text
        headerLabel.font = Fonts.semibold.withSize(17)
        headerLabel.text = self.title
        headerLabel.textAlignment = .center
        self.addSubview(headerLabel)
        
        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(Colors.orange, for: .normal)
        doneButton.setTitleColor(Colors.extraLightText, for: .disabled)
        doneButton.titleLabel?.font = Fonts.semibold.withSize(17)
        doneButton.addTarget(self, action: #selector(didTapDone), for: .touchUpInside)
        doneButton.contentHorizontalAlignment = .right
        doneButton.contentEdgeInsets.right = Constants.margin
        self.addSubview(doneButton)
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(Colors.orange, for: .normal)
        cancelButton.titleLabel?.font = Fonts.regular.withSize(17)
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        cancelButton.contentHorizontalAlignment = .left
        cancelButton.contentEdgeInsets.left = Constants.margin
        self.addSubview(cancelButton)
        
        cancelButton.alpha = 0
        doneButton.alpha = 0
                
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func didTapDone() {
        doneButtonAction?()
    }
    
    @objc func didTapCancel() {
        cancelButtonAction?()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(
            width: size.width,
            height: 66)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        doneButton.contentEdgeInsets.right = Constants.margin + extraInset.right
        cancelButton.contentEdgeInsets.left = Constants.margin + extraInset.left
                
        headerSeparator.frame = self.bounds
        
        handleView.frame = CGRect(
            x: 0, y: 0, width: self.bounds.width,
            height: handleView.sizeThatFits(self.bounds.size).height)
        
        let offset: CGFloat = showsHandle ? 14 : 7
        
        headerLabel.frame = CGRect(x: 0, y: offset, width: self.bounds.width, height: self.bounds.height - offset)
        
        doneButton.frame = CGRect(
            x: self.bounds.maxX - 80,
            y: offset, width: 80,
            height: self.bounds.height-offset)
        
        cancelButton.frame = CGRect(x: 0, y: offset, width: 100, height: self.bounds.height-offset)
        
    }
    
}

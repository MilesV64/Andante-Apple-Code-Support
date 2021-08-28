//
//  PlaceholderTextView.swift
//  Andante
//
//  Created by Miles Vinson on 7/23/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class PlaceHolderTextView: UITextView {
    
    public var placeholder: String?
    
    private var placeholderTextView: UITextView?
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        self.tintColor = Colors.orange
        self.backgroundColor = .clear
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3.5
        paragraphStyle.paragraphSpacing = 5
        
        let attributes: [ NSAttributedString.Key : Any ] = [
            .foregroundColor: Colors.text,
            .font: Fonts.regular.withSize(17),
            .paragraphStyle: paragraphStyle
        ]
        
        self.attributedText = NSAttributedString(string: "", attributes: attributes)
        self.typingAttributes = attributes
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var text: String! {
        didSet {
            if self.isFirstResponder == false {
                if text.isEmpty {
                    showPlaceholder()
                }
                else {
                    hidePlaceholder()
                }
            }
        }
    }
    
    override var textContainerInset: UIEdgeInsets {
        didSet {
            placeholderTextView?.textContainerInset = textContainerInset
        }
    }
    
    private func showPlaceholder() {
        
        if self.placeholderTextView != nil {
            configurePlaceholder()
        }
        else {
            self.placeholderTextView = UITextView()
            self.addSubview(placeholderTextView!)
            configurePlaceholder()
        }
        
    }
    
    private func configurePlaceholder() {
        guard let placeholderTextView = self.placeholderTextView else { return }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3.5
        paragraphStyle.paragraphSpacing = 5
        
        let attributes: [ NSAttributedString.Key : Any ] = [
            .foregroundColor: Colors.extraLightText,
            .font: Fonts.regular.withSize(17),
            .paragraphStyle: paragraphStyle
        ]
        
        placeholderTextView.textContainerInset = self.textContainerInset
        
        placeholderTextView.isUserInteractionEnabled = false
        placeholderTextView.backgroundColor = .clear
        placeholderTextView.attributedText = NSAttributedString(string: placeholder ?? "", attributes: attributes)
        
    }
    
    private func hidePlaceholder() {
        if let placeholder = self.placeholderTextView {
            placeholder.removeFromSuperview()
            self.placeholderTextView = nil
        }
    }
    
    @discardableResult
    override func becomeFirstResponder() -> Bool {
        if canBecomeFirstResponder == false {
            return false
        }
        
        hidePlaceholder()
        return super.becomeFirstResponder()
    }
    
    @discardableResult
    override func resignFirstResponder() -> Bool {
        
        if text.isEmpty {
            showPlaceholder()
        }
        else {
            hidePlaceholder()
        }
        
        return super.resignFirstResponder()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        placeholderTextView?.frame = self.bounds
    }

}

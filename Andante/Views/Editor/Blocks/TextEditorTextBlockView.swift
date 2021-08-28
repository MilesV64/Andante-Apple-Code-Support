//
//  TextEditorTextBlockView.swift
//  Andante
//
//  Created by Miles Vinson on 4/7/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class TextEditorTextBlockView: TextEditorBlockView, UITextViewDelegate {
        
    class TextEditorTextView: UITextView {
        
        override func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
            //intentionally empty to cancel uitextview auto scrolling the parent scroll view
        }
        
        public var deleteBackwardHandler: (()->())?
        override func deleteBackward() {
            if self.text.isEmpty {
                deleteBackwardHandler?()
            }
            super.deleteBackward()
        }
    }
    
    override public var blockType: TextEditorBlock.BlockType {
        return .text
    }
    
    public var textStyle: TextEditorBlock.TextStyle = .body {
        didSet {
            updateStyle(oldValue)
        }
    }
    
    public var string: String {
        get {
            return textView.text
        }
        set {
            let attributedString = NSAttributedString(
                string: newValue,
                attributes: textStyle.attributes)
            textView.attributedText = attributedString
        }
    }
    
    private var bulletView: UIView?
    
    public var isEditing = false
    
    private let textView = TextEditorTextView()
    
    init(_ style: TextEditorBlock.TextStyle) {
        super.init()
        
        self.textStyle = style
        updateStyle(nil)
        
        textView.backgroundColor = .clear
        textView.tintColor = Colors.orange
        textView.isScrollEnabled = false
        textView.delegate = self
        self.addSubview(textView)
        
        textView.deleteBackwardHandler = {
            [weak self] in
            guard let self = self else { return }
            self.delegate?.textEditorBlockDidDelete(self)
        }
        
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func contentHeight(for width: CGFloat) -> CGFloat {
        setTextContainerInset()
        
        let actualWidth: CGFloat
        if textStyle == .bullet || textStyle == .numbered {
            actualWidth = width - 20
        }
        else {
            actualWidth = width
        }
        
        let textHeight = textView.sizeThatFits(CGSize(width: actualWidth, height: .infinity)).height
        
        let lineHeight = (textStyle.attributes[.font] as! UIFont).lineHeight
        
        let height = max(lineHeight, textHeight)
        
        return height
    }
    
    override var padding: UIEdgeInsets {
        switch textStyle {
        case .title: return UIEdgeInsets(t: 8, b: 2)
        case .header: return UIEdgeInsets(t: 6, b: 0)
        default: return UIEdgeInsets(t: 0, b: 0)
        }
        
    }
    
    private func createBulletView(animate: Bool) {
        guard bulletView == nil else { return }
        
        bulletView = UIView()
        bulletView?.backgroundColor = Colors.text
        if animate {
            bulletView?.alpha = 0
            bulletView?.transform = CGAffineTransform(scaleX: 0.75, y: 0.75).concatenating(CGAffineTransform(translationX: -8, y: 0))
        }
        contentView.addSubview(bulletView!)
        layoutBullet()
        
        UIView.animateWithCurve(duration: animate ? 0.6 : 0, curve: UIView.CustomAnimationCurve.exponential.easeOut, animation: {
            self.bulletView?.alpha = 1
            self.bulletView?.transform = .identity
            self.layoutTextView()
        }, completion: nil)
    }
    
    private func removeBulletView(animate: Bool) {
        if let bulletView = bulletView {
            self.bulletView = nil
            UIView.animateWithCurve(duration: 0.4, curve: UIView.CustomAnimationCurve.exponential.easeOut, animation: {
                bulletView.alpha = 0
                bulletView.transform = CGAffineTransform(scaleX: 0.75, y: 0.75).concatenating(CGAffineTransform(translationX: -6, y: 0))
                self.layoutTextView()
            }, completion: {
                bulletView.removeFromSuperview()
            })
        }
    }
    
    private func updateTextSize(animate: Bool) {
        UIView.transition(with: self.textView, duration: animate ? 0.1 : 0, options: [.transitionCrossDissolve]) {
            self.textView.textStorage.setAttributes(self.textStyle.attributes, range: self.textView.textRange)
            self.textView.typingAttributes = self.textStyle.attributes
        } completion: { (complete) in }
    }
    
    private func updateStyle(_ oldStyle: TextEditorBlock.TextStyle?) {
        let bulletStyles: [TextEditorBlock.TextStyle] = [.bullet, .numbered]
        
        if let oldStyle = oldStyle {
            if bulletStyles.contains(oldStyle) {
                if bulletStyles.contains(textStyle) {
                    //change from bullet to number if needed
                }
                else {
                    removeBulletView(animate: true)
                    updateTextSize(animate: textStyle != .body)
                }
            }
            else {
                if bulletStyles.contains(textStyle) {
                    createBulletView(animate: true)
                    updateTextSize(animate: oldStyle != .body)
                }
                else {
                    updateTextSize(animate: true)
                }
            }
            
            if lastHeight != height(for: bounds.width) {
                delegate?.textEditorBlockDidChangeSize(self)
            }
            
        }
        else {
            if bulletStyles.contains(textStyle) {
                createBulletView(animate: false)
            }
            
            updateTextSize(animate: false)
        }
        
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if lastHeight != height(for: bounds.width) {
            delegate?.textEditorBlockDidChangeSize(self)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if text == "\n" {
            if range.location == 0 {
                let trailingText = self.textView.text ?? ""
                self.textView.text = ""
                delegate?.textEditorBlockDidReturn(self, trailingText: trailingText)
            }
            else {
                let index = textView.text.index(textView.text.startIndex, offsetBy: range.location)
                let trailingText = textView.text.suffix(from: index)
                self.textView.text = String(textView.text.prefix(upTo: index))
                delegate?.textEditorBlockDidReturn(self, trailingText: String(trailingText))
            }
            
            return false
        }
        
        return true
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        delegate?.textEditorBlockWillStartEditing(self)
        isEditing = true
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.textEditorBlockDidChangeSelection(self, selectionFrame: textView.currentSelectionRect)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        isEditing = false
        delegate?.textEditorBlockDidEndEditing(self)
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        delegate?.textEditorBlockDidChangeSelection(self, selectionFrame: textView.currentSelectionRect)
    }
    
    @discardableResult
    override func becomeFirstResponder() -> Bool {
        return textView.becomeFirstResponder()
    }
    
    @discardableResult
    override func resignFirstResponder() -> Bool {
        return textView.resignFirstResponder()
    }
    
    override var isFirstResponder: Bool {
        return textView.isFirstResponder
    }
    
    public func setCursorAtEnd() {
        textView.selectedRange = NSRange(location: textView.textStorage.length, length: 0)
    }
    
    public func setCursorAtStart() {
        textView.selectedRange = NSRange(location: 0, length: 0)
    }
    
    override func didSelectBlock() {
        super.didSelectBlock()
        
        self.becomeFirstResponder()
        
    }
    
    private func layoutBullet() {
        let lineHeight = (textStyle.attributes[.font] as! UIFont).lineHeight
        bulletView?.contextualFrame = CGRect(
            x: Constants.margin/2, y: 6 + lineHeight/2 - 3,
            width: 6, height: 6)
        bulletView?.roundCorners(3)
    }
    
    private func setTextContainerInset() {
        textView.textContainerInset = UIEdgeInsets(
            top: 6 + padding.top,
            left: Constants.margin - 5,
            bottom: 6 + padding.bottom,
            right: Constants.margin - 5)
    }
    
    private func layoutTextView() {
        if bulletView != nil {
            textView.frame = self.bounds.inset(by: UIEdgeInsets(l: 20))
        }
        else {
            textView.frame = self.bounds

        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setTextContainerInset()

        layoutBullet()
        
        layoutTextView()
        
    }
}

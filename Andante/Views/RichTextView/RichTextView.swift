//
//  RichTextView.swift
//  Andante
//
//  Created by Miles Vinson on 6/11/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

extension String {
    func char(at location: Int) -> Character {
        return self[index(startIndex, offsetBy: location)]
    }
}

protocol RichTextViewDelegate: class {
    func richTextView(didChangeStyle style: RichTextView.TextStyle)
    func richTextViewDidBeginEditing()
    func richTextViewDidEndEditing()
    func richTextViewDidChangeText()
    func richTextViewDidScroll()
    func richTextViewDidChangeSelection()
}

class RichTextView: UITextView, UITextViewDelegate, NSTextStorageDelegate {
    
    public weak var richTextDelegate: RichTextViewDelegate?
    
    private let toolBar = UIToolbar()
    private var _currentStyle: TextStyle = .body
    
    private var bodyButton: UIBarButtonItem!
    private var headerButton: UIBarButtonItem!
    private var titleButton: UIBarButtonItem!
    
    public var currentStyle: TextStyle {
        return _currentStyle
    }
    
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        self.backgroundColor = .clear
                            
        self.textStorage.delegate = self
        self.delegate = self
        
        self._currentStyle = .title
        updateStyle()

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
        //intentionally empty to cancel uitextview auto scrolling
    }
    
    public func setStyle(_ style: TextStyle) {
        self._currentStyle = style
        updateStyle()
        richTextDelegate?.richTextView(didChangeStyle: style)
    }
    
    private func updateStyle() {
        
        let charRange = currentParagraphRange()
        if charRange.location == NSNotFound {
            print("Not found")
            return
        }
        
        textStorage.beginEditing()
        textStorage.setAttributes(self._currentStyle.attributes, range: charRange)
        textStorage.endEditing()
        
        self.typingAttributes = self._currentStyle.attributes
        
    }
    
    private func updateButtons() {
        titleButton.style = _currentStyle == .title ? .done : .plain
        headerButton.style = _currentStyle == .header ? .done : .plain
        bodyButton.style = _currentStyle == .body ? .done : .plain
    }
    
    private var didGoToNewLine = false
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if text == "\n" {
            didGoToNewLine = true
        }
        
        return true
    }
        
    func textViewDidChangeSelection(_ textView: UITextView) {
        
        if didGoToNewLine {
            let range = currentParagraphRange()
            if range.location != NSNotFound {
                self._currentStyle = .body
                
                textStorage.beginEditing()
                textStorage.addAttributes(self._currentStyle.attributes, range: range)
                textStorage.endEditing()
                
                self.typingAttributes = self._currentStyle.attributes
                
                richTextDelegate?.richTextView(didChangeStyle: _currentStyle)
            }
            
            didGoToNewLine = false
            return
        }
        
        let range = currentParagraphRange()
        
        if range.location >= 0 && range.location < textView.text.count {
            let att = textStorage.attributes(at: range.location, effectiveRange: nil)
            
            if let style = att[.customStyle] as? Int {
                switch style {
                case 0:
                    if self._currentStyle != .title {
                        self._currentStyle = .title
                        richTextDelegate?.richTextView(didChangeStyle: currentStyle)
                    }
                    typingAttributes = TextStyle.title.attributes
                case 1:
                    if self._currentStyle != .header {
                        self._currentStyle = .header
                        richTextDelegate?.richTextView(didChangeStyle: currentStyle)
                    }
                    typingAttributes = TextStyle.header.attributes
                default:
                    if self._currentStyle != .body {
                        self._currentStyle = .body
                        richTextDelegate?.richTextView(didChangeStyle: currentStyle)
                    }
                    typingAttributes = TextStyle.body.attributes
                }
            }
        } else {
            typingAttributes = _currentStyle.attributes
        }
        
        self.richTextDelegate?.richTextViewDidChangeSelection()
        
    }
    
    func typingAttributesEqual(_ attributes: [NSAttributedString.Key : Any]) -> Bool {
        return attributes[.font] as? UIFont == typingAttributes[.font] as? UIFont
        
    }
    
    func currentParagraphRange() -> NSRange {
        return (self.textStorage.string as NSString).paragraphRange(for: self.selectedRange)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        richTextDelegate?.richTextViewDidBeginEditing()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        richTextDelegate?.richTextViewDidEndEditing()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        typingAttributes = _currentStyle.attributes
        richTextDelegate?.richTextViewDidChangeText()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        richTextDelegate?.richTextViewDidScroll()
    }
    
}

//MARK: - Styles
extension RichTextView {
    
    enum TextStyle {
        case body, header, title
        
        var attributes: [NSAttributedString.Key : Any] {
            switch self {
            case .body:
                return EntryTextAttributes.BodyAttributes
            case .header:
                return EntryTextAttributes.HeaderAttributes
            case .title:
                return EntryTextAttributes.TitleAttributes
            }
        }
    }
    
}

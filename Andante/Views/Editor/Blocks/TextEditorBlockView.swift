//
//  TextEditorBlockView.swift
//  Andante
//
//  Created by Miles Vinson on 4/4/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

protocol TextEditorBlockDelegate: class {
    func textEditorBlockDidChangeSize(_ block: TextEditorBlockView)
    
    func textEditorBlockDidReturn(_ block: TextEditorTextBlockView, trailingText: String)
    func textEditorBlockWillStartEditing(_ block: TextEditorTextBlockView)
    func textEditorBlockDidEndEditing(_ block: TextEditorTextBlockView)
    func textEditorBlockDidDelete(_ block: TextEditorTextBlockView)
    func textEditorBlockDidChangeSelection(_ block: TextEditorTextBlockView, selectionFrame: CGRect)
    
    func textEditorBlockDidSelectImage(_ block: TextEditorImageBlockView, imageView: UIImageView)
    func textEditorBlockDidSelectVideo(_ block: TextEditorImageBlockView, url: URL)
}

class TextEditorBlockView: UIView {
    
    public weak var delegate: TextEditorBlockDelegate?
    
    public var blockType: TextEditorBlock.BlockType {
        return .text
    }
    
    public var contentView = UIView()
    
    public var lastHeight: CGFloat?
    
    public func showBackground(animated: Bool) {
        UIView.animate(withDuration: animated ? 0.2 : 0) {
            self.contentView.backgroundColor = Colors.lightColorOpaque.withAlphaComponent(0.5)
        }
    }
    
    public func hideBackground(animated: Bool) {
        UIView.animate(withDuration: animated ? 0.25 : 0) {
            self.contentView.backgroundColor = .clear
        }
    }
    
    private let tapGesture = UITapGestureRecognizer()
    
    init() {
        super.init(frame: .zero)
        
        contentView.roundCorners(6)
        addSubview(contentView)
        
        tapGesture.addTarget(self, action: #selector(didSelectBlock))
        //addGestureRecognizer(tapGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    @objc public func didSelectBlock() {
        
    }
    
    public func height(for width: CGFloat) -> CGFloat {
        let height = contentHeight(for: width)
        self.lastHeight = height
        return height
    }
    
    public func contentHeight(for width: CGFloat) -> CGFloat {
        return 0
    }
    
    public var padding: UIEdgeInsets {
        return .zero
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.frame = self.bounds.inset(
            by: UIEdgeInsets(
                top: padding.top,
                left: Constants.margin/2,
                bottom: padding.bottom,
                right: Constants.margin/2))
        
    }
}


class TextEditorDividerBlockView: TextEditorBlockView {
    
    override public var blockType: TextEditorBlock.BlockType {
        return .divider
    }
    
    override init() {
        super.init()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
}

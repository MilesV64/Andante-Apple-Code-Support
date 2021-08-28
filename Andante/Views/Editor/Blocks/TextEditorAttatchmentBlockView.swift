//
//  TextEditorAttatchmentBlockView.swift
//  Andante
//
//  Created by Miles Vinson on 4/7/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit
import AVKit

class TextEditorImageBlockView: TextEditorBlockView {
    
    override public var blockType: TextEditorBlock.BlockType {
        return .attatchment
    }
    
    public var attatchmentType: TextEditorBlock.AttatchmentType = .image
        
    private let imageView = UIImageView()
    
    private let tapGesture = UITapGestureRecognizer()
    private let containerView = UIView()
    
    private var playButtonBackground: UIVisualEffectView?
    private var playButtonImage: UIImageView?
    private var playButtonImageDuplicate: UIImageView?
    
    public var videoURL: URL? {
        didSet {
            if videoURL != nil {
                attatchmentType = .video
                addPlayButton()
            } else {
                attatchmentType = .image
                removePlayButton()
            }
        }
    }
    private var aspect: CGFloat?
    
    override init() {
        super.init()
        
        addSubview(containerView)
        
        imageView.roundCorners(8)
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        containerView.addSubview(imageView)
        
        imageView.addGestureRecognizer(tapGesture)
        tapGesture.addTarget(self, action: #selector(didTapImage))
        
    }
    
    @objc func didTapImage() {
        if false { // let url = self.videoURL {
            //self.delegate?.textEditorBlockDidSelectVideo(self, url: url)
        }
        else {
            self.delegate?.textEditorBlockDidSelectImage(self, imageView: imageView)
        }
    }
    
    public func setImage(_ image: UIImage?, aspect: CGFloat? = nil) {
        self.imageView.image = image
        
        if aspect != nil {
            self.aspect = aspect
        }
        else if let image = image {
            self.aspect = image.size.height / image.size.width
        }
        
    }
    
    private func addPlayButton() {
        let bgView = UIVisualEffectView(effect: UIBlurEffect(style: .prominent))
        bgView.isUserInteractionEnabled = false
        imageView.addSubview(bgView)
        bgView.translatesAutoresizingMaskIntoConstraints = false
        bgView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
        bgView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
        bgView.heightAnchor.constraint(equalToConstant: 62).isActive = true
        bgView.widthAnchor.constraint(equalToConstant: 62).isActive = true
        self.playButtonBackground = bgView
    }
    
    private func removePlayButton() {
        playButtonBackground?.removeFromSuperview()
        playButtonBackground = nil
    }
    
    override func contentHeight(for width: CGFloat) -> CGFloat {
        let actualWidth = width - Constants.smallMargin*2
        return actualWidth * (self.aspect ?? 1) + 12
    }
    
    override var padding: UIEdgeInsets {
        return UIEdgeInsets(t: 10, b: 10)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    private func layoutPlayButton() {
        if let bgView = playButtonBackground {
            let maskView = UIImageView(image: UIImage(name: "play.circle.fill", pointSize: 40, weight: .semibold))
            maskView.sizeToFit()
            maskView.center = bgView.bounds.center
            maskView.tintColor = .black
            bgView.mask = maskView
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        containerView.frame = self.bounds.insetBy(dx: Constants.smallMargin, dy: 6)
        
        if imageView.superview == containerView {
            imageView.frame = containerView.bounds
        }
        
        layoutPlayButton()
        
    }
}

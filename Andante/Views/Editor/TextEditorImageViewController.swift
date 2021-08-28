//
//  ImageViewController.swift
//  Andante
//
//  Created by Miles Vinson on 4/7/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class GestureScrollView: UIScrollView {
    
    public var allowedGestures: [UIGestureRecognizer] = []
    
    init() {
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if zoomScale == 1 {
            if let _ = gestureRecognizer as? UIPinchGestureRecognizer {
                return super.gestureRecognizerShouldBegin(gestureRecognizer)
            } else {
                return allowedGestures.contains(gestureRecognizer)
            }
        }
        
        return true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
}

class TextEditorImageViewer: UIView, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    private let shadowView = UIView()
    let imageView: UIImageView
    
    private weak var originalSuperview: UIView?
    
    private var isAnimating = true
    private let scrollView = GestureScrollView()
    private let doubleTapGesture = UITapGestureRecognizer()
    
    private let panGesture = UIPanGestureRecognizer()
    
    public var closeHandler: (()->())?
    
    private var image: UIImage {
        return imageView.image!
    }
    
    init(_ imageView: UIImageView) {
        self.imageView = imageView
        super.init(frame: .zero)
        
        self.originalSuperview = imageView.superview
        
        self.backgroundColor = .clear
        
        imageView.isUserInteractionEnabled = false
        
        
        shadowView.backgroundColor = Colors.foregroundColor
        shadowView.roundCorners(8)
        shadowView.setShadow(radius: 24, yOffset: 8, opacity: 0, color: UIColor.black.withAlphaComponent(0.18))
        
        scrollView.clipsToBounds = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 5
        scrollView.delegate = self
        scrollView.alwaysBounceVertical = true
        scrollView.allowedGestures.append(doubleTapGesture)
        scrollView.allowedGestures.append(panGesture)
        addSubview(scrollView)
        
        scrollView.addGestureRecognizer(doubleTapGesture)
        doubleTapGesture.addTarget(self, action: #selector(didDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        
        addGestureRecognizer(panGesture)
        panGesture.delegate = self
        panGesture.addTarget(self, action: #selector(handlePan))
        
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError()
    }

    @objc func didDoubleTap() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
            
            if self.scrollView.zoomScale == 1 {
                self.scrollView.zoom(to: self.zoomRectForScale(self.scrollView.maximumZoomScale, center: self.doubleTapGesture.location(in: self.scrollView)), animated: false)
            } else {
                self.scrollView.setZoomScale(1, animated: false)
            }
            
            self.layoutScrollView()
        }, completion: nil)
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer === panGesture && scrollView.zoomScale == 1
    }
    
    @objc func handlePan() {
        let translation = panGesture.translation(in: self)
        
        if panGesture.state == .began || panGesture.state == .changed {
            let easedTranslation = CGPoint(
                x: easeTranslation(translation.x, min: 0, max: 0, alpha: 0.005),
                y: easeTranslation(translation.y, min: 0, max: 0, alpha: 0.0025))
            
            scrollView.frame.origin = CGPoint(x: easedTranslation.x, y: easedTranslation.y)
            
            let combinedTransform = abs(translation.x) + abs(translation.y)
            let cornerRadius = min(1, (combinedTransform / 100)) * 8
            imageView.layer.cornerRadius = cornerRadius
            
            let alpha = combinedTransform / 200
            backgroundColor = backgroundColor?.withAlphaComponent(1 - alpha)
            
            let scale = 1 - min(0.25, alpha*0.25)
            imageView.transform = CGAffineTransform(scaleX: scale, y: scale)
            
            shadowView.layer.shadowOpacity = Float(alpha)
            shadowView.transform = imageView.transform
        }
        else {
            let v = panGesture.velocity(in: self)
            let velocity: CGFloat = abs(v.x) + abs(v.y)
            
            if velocity > 500 {
                close()
            }
            else if (abs(translation.x) + abs(translation.y)) > 200 {
                close()
            }
            else {
                UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.92, initialSpringVelocity: 0, options: [.curveEaseOut]) {
                    self.scrollView.frame.origin = .zero
                    self.imageView.transform = .identity
                    self.shadowView.transform = .identity
                    self.backgroundColor = self.backgroundColor?.withAlphaComponent(1)
                } completion: { (complete) in }
                animateCornerRadius(to: 0)
                animateShadow(to: 0)
            }
        }
    }
    
    func close() {
        if let originalSuperview = self.originalSuperview {
            let frame = originalSuperview.convert(originalSuperview.bounds, to: self.scrollView)
            self.isAnimating = true
            UIView.animate(
                withDuration: 0.6,
                delay: 0,
                usingSpringWithDamping: 0.76,
                initialSpringVelocity: 0,
                options: [.curveEaseOut]
            ) {
                self.imageView.contextualFrame = frame
                self.imageView.transform = .identity
                self.shadowView.contextualFrame = frame
                self.shadowView.transform = .identity
                self.backgroundColor = .clear
            } completion: { (complete) in
                self.imageView.isUserInteractionEnabled = true
                originalSuperview.addSubview(self.imageView)
                self.imageView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
                self.closeHandler?()
            }
        }
        
        animateCornerRadius(to: 8)
        animateShadow(to: 0)
    }
    
    func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.bounds.size.height / scale
        zoomRect.size.width = imageView.bounds.size.width / scale
        let newCenter = scrollView.convert(center, to: imageView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        layoutScrollView()
    }
    
    public func animate(extraAnimations: (()->())?) {
                
        let frame = imageView.convert(imageView.bounds, to: self.scrollView)
        self.scrollView.addSubview(shadowView)
        self.scrollView.addSubview(imageView)
        imageView.frame = frame
        shadowView.frame = frame
        
        self.isAnimating = false
        UIView.animateWithCurve(duration: 0.5, curve: UIView.CustomAnimationCurve.exponential.easeOut, animation: {
            self.layoutSubviews()
            self.backgroundColor = Colors.foregroundColor
            extraAnimations?()
        }, completion: {
            self.isAnimating = false
        })
        
        animateCornerRadius(to: 0)
    }
    
    private func animateCornerRadius(to radius: CGFloat) {
        let anim = CABasicAnimation(keyPath: "cornerRadius")
        anim.fromValue = imageView.layer.cornerRadius
        anim.toValue = radius
        anim.duration = 0.25
        imageView.layer.add(anim, forKey: "cornerRadius")
        imageView.layer.cornerRadius = radius
    }
    
    private func animateShadow(to opacity: Float) {
        let anim = CABasicAnimation(keyPath: "shadowOpacity")
        anim.fromValue = shadowView.layer.shadowOpacity
        anim.toValue = opacity
        anim.duration = 0.25
        shadowView.layer.add(anim, forKey: "shadowOpacity")
        shadowView.layer.shadowOpacity = opacity
    }
    
    private func layoutImage() {
        let aspect = image.size.height / image.size.width
        
        if bounds.height < bounds.width*aspect {
            imageView.bounds.size = CGSize(width: bounds.height / aspect, height: bounds.height)
        }
        else {
            imageView.bounds.size = CGSize(width: bounds.width, height: bounds.width * aspect)
        }
        
        imageView.center = CGPoint(x: imageView.bounds.width/2, y: imageView.bounds.height/2)
        
        shadowView.contextualFrame = imageView.frame
    }
    
    private func layoutScrollView() {
        let scaledImageSize = CGSize(
            width: imageView.bounds.width * scrollView.zoomScale,
            height: imageView.bounds.height * scrollView.zoomScale)
        
        scrollView.contentSize = scaledImageSize
        
        let diff = CGPoint(
            x: max(0, scrollView.bounds.width - scaledImageSize.width),
            y: max(0, scrollView.bounds.height - scaledImageSize.height))
        scrollView.contentInset = UIEdgeInsets(
            top: diff.y/2, left: diff.x/2, bottom: diff.y/2, right: diff.x/2)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        scrollView.contextualFrame = self.bounds
        
        if isAnimating { return }
        
        layoutImage()
        
        layoutScrollView()
        
    }
    
}

//
//  TransitionManager.swift
//  Andante
//
//  Created by Miles Vinson on 9/15/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

protocol TransitionDelegate: class {
    func viewWillOpen()
    func viewWillClose()
}

class TransitionManager: NSObject {
    
    public let gesture = UIPanGestureRecognizer()
    private var firstView: UIView!
    private var secondView: UIView!
    private var parentView: UIView!
    
    private var dimView = UIView()
    
    public var statusBarHandler: ((_:UIStatusBarStyle)->Void)?
    
    private var screenWidth: CGFloat {
        return parentView.bounds.width
    }
    
    private var isDragging = false
    
    private enum ActiveView {
        case first, second
    }
    private var activeView: ActiveView = .first
    
    //called right before it opens
    public var openHandler: (()->Void)?
    
    public var didOpenHandler: (()->Void)?
    public var didCloseHandler: (()->Void)?
    
    private let closedScale: CGFloat = 0.92
    
    public var isEnabled = true {
        didSet {
            gesture.isEnabled = isEnabled
            secondView.isHidden = !isEnabled
            if !isEnabled {
                setClosedPosition()
            }
        }
    }
    
    init(firstView: UIView, secondView: UIView, parentView: UIView) {
        
        self.firstView = firstView
        self.secondView = secondView
        self.parentView = parentView
        
        secondView.roundCorners(UIDevice.current.deviceCornerRadius())
        secondView.clipsToBounds = true
        
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        dimView.alpha = 0
        secondView.addSubview(dimView)
        
        super.init()
                
        gesture.addTarget(self, action: #selector(handleGesture(_:)))
        parentView.addGestureRecognizer(gesture)
        
    }
    
    public func updateLayout() {
        guard isEnabled else { return }
        
        dimView.contextualFrame = CGRect(x: 0, y: 0, width: secondView.bounds.width, height: secondView.bounds.height)
        dimView.transform = CGAffineTransform(translationX: -screenWidth, y: 0)
        
        if isDragging { return }
                
        if activeView == .first {
            firstView.transform = .identity
            secondView.transform = CGAffineTransform(translationX: screenWidth, y: 0)
        }
        else {
            firstView.transform = CGAffineTransform(scaleX: closedScale, y: closedScale)
            secondView.transform = .identity
        }
        
    }
    
    private func setOpenPosition() {
        self.statusBarHandler?(.default)
        self.firstView.transform = CGAffineTransform(scaleX: closedScale, y: closedScale)
        self.dimView.alpha = 1
        self.secondView.transform = .identity
        
        didOpenHandler?()
    }
    
    private func setClosedPosition() {
        self.statusBarHandler?(.lightContent)
        self.firstView.transform = .identity
        self.dimView.alpha = 0
        self.secondView.transform = CGAffineTransform(translationX: self.screenWidth, y: 0)
        
        self.didCloseHandler?()
    }
    
    public func open() {
        openHandler?()
        isDragging = true
        UIView.animateWithCurve(duration: 0.65, x1: 0.2, y1: 1, x2: 0.36, y2: 1, animation: {
            self.setOpenPosition()
        }, completion: {
            [weak self] in
            guard let self = self else { return }
            self.isDragging = false
            self.activeView = .second
        })
    }
    
    public func close() {
        isDragging = true
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            self.setClosedPosition()
        }, completion: {
            [weak self] complete in
            guard let self = self else { return }
            self.isDragging = false
            self.activeView = .first
        })
    }
    
    @objc func handleGesture(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            isDragging = true
            if activeView != .second {
                openHandler?()
                if let secondView = secondView as? TransitionDelegate {
                    secondView.viewWillOpen()
                }
            }
            else {
                if let secondView = secondView as? TransitionDelegate {
                    secondView.viewWillClose()
                }
            }
        }
        else if gesture.state == .changed {
            self.gestureDidUpdate(gesture)
        }
        else {
            self.gestureDidEnd(gesture)
        }
    }
    
    private func gestureDidUpdate(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: parentView).x
        
        if activeView == .first {
            if translation > 0 {
                firstView.transform = .identity
                dimView.alpha = 0
                secondView.transform = CGAffineTransform(translationX: screenWidth, y: 0)
            }
            else {
                let progress = -translation/screenWidth
                let scale = 1 - progress*(1-closedScale)
                dimView.alpha = progress
                firstView.transform = CGAffineTransform(scaleX: scale, y: scale)
                secondView.transform = CGAffineTransform(translationX: screenWidth + translation, y: 0)
            }
        }
        else {
            if translation < 0 {
                firstView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                dimView.alpha = 1
                secondView.transform = .identity
            }
            else {
                let progress = translation/screenWidth
                let scale = closedScale + progress*(1-closedScale)
                dimView.alpha = 1 - progress
                firstView.transform = CGAffineTransform(scaleX: scale, y: scale)
                secondView.transform = CGAffineTransform(translationX: translation, y: 0)
            }
        }
        
    }
    
    private func gestureDidEnd(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: parentView).x
        let velocity = getVelocity(gesture)
        
        if velocity < -2 {
            //print("Left velocity", translation, velocity)
            moveLeft(with: velocity)
        }
        else if velocity > 2 {
            //print("Right velocity", translation, velocity)
            moveRight(with: velocity)
        }
        else {
            let midPoint = activeView == .first ? -screenWidth/2 : screenWidth/2
            if translation < midPoint {
                //print("Left", translation)
                moveLeft(with: nil)
            }
            else {
                //print("Right", translation)
                moveRight(with: nil)
            }
        }
    }
    
    private func moveLeft(with velocity: CGFloat?) {
        var modifiedVelocity = velocity
        if activeView != .second {
            activeView = .second
            modifiedVelocity? *= 2
        }
        
        if let velocity = modifiedVelocity {
            UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: -velocity, options: .curveLinear, animations: {
                self.setOpenPosition()
            }, completion: {
                [weak self] complete in
                guard let self = self else { return }
                self.isDragging = false
            })
        }
        else {
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                self.setOpenPosition()
            }, completion: {
                [weak self] complete in
                guard let self = self else { return }
                self.isDragging = false
            })
        }
        
    }
    
    private func moveRight(with velocity: CGFloat?) {
        var modifiedVelocity = velocity
        if activeView != .first {
            activeView = .first
            modifiedVelocity? *= 2
        }
        
        if let velocity = modifiedVelocity {
            UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: velocity, options: .curveLinear, animations: {
                self.setClosedPosition()
            }, completion: {
                [weak self] complete in
                guard let self = self else { return }
                self.isDragging = false
            })
        }
        else {
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                self.setClosedPosition()
            }, completion: {
                [weak self] complete in
                guard let self = self else { return }
                self.isDragging = false
            })
        }
    }
    
    private func getVelocity(_ gesture: UIPanGestureRecognizer) -> CGFloat {
        let originalVelocity = gesture.velocity(in: parentView).x
        
        var velocity: CGFloat = 0
        if originalVelocity > 0 {
            velocity = originalVelocity / (parentView.bounds.width - gesture.translation(in: parentView).x)
        }
        else if originalVelocity < 0 {
            velocity = originalVelocity / parentView.bounds.width
        }
        
        return velocity
    }
    
}

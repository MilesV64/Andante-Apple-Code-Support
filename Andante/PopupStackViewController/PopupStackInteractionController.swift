//
//  PopupStackInteractionController.swift
//  Andante
//
//  Created by Miles on 10/29/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

protocol PopupStackInteractionControllerDelegate: AnyObject {
    
    func interactionControllerDidTapOutside(_ controller: PopupStackInteractionController)
    
    func interactionControllerWillCommitDismissal(_ controller: PopupStackInteractionController)
    func interactionControllerDidCommitDismissal(_ controller: PopupStackInteractionController)
    
}

class PopupStackInteractionController: NSObject, UIGestureRecognizerDelegate {
    
    
    weak var popupViewController: PopupStackViewController? {
        didSet {
            self.setupGestures()
        }
    }
    
    private(set) var isDragging: Bool = false
    
    // - Gestures
    
    private let outsideTapGesture = UITapGestureRecognizer()
    
    private var dismissalGestureRecognizer = UIPanGestureRecognizer()
    
    private var scrollGestureRecognizer: UIPanGestureRecognizer?
    
    
    // MARK: - Setup
    
    private func setupGestures() {
        guard let popupViewController = self.popupViewController else { return }
        
        self.outsideTapGesture.addTarget(self, action: #selector(self.handleOutsideTap))
        self.outsideTapGesture.delegate = self
        popupViewController.view.addGestureRecognizer(self.outsideTapGesture)
        
        self.dismissalGestureRecognizer.addTarget(self, action:  #selector(self.handleDismissalGesture(_:)))

    }
    
    /// Call when the primary (visible) content view changes, in order to update gestures
    public func didChangePrimaryContentView(_ view: PopupStackViewController.ContentContainerView) {
        view.addGestureRecognizer(self.dismissalGestureRecognizer)
        
        if let scrollGestureRecognizer = self.scrollGestureRecognizer, let gestureView = scrollGestureRecognizer.view {
            gestureView.removeGestureRecognizer(scrollGestureRecognizer)
            self.scrollGestureRecognizer = nil
        }
        
        if let scrollView = view.contentView.dismissalHandlingScrollView {
            let dismissalGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handleDismissalGesture(_:)))
            dismissalGestureRecognizer.delegate = self

            scrollView.addGestureRecognizer(dismissalGestureRecognizer)
            scrollView.panGestureRecognizer.require(toFail: dismissalGestureRecognizer)
            
            self.scrollGestureRecognizer = dismissalGestureRecognizer
        }
    }
    
    
    // MARK: - GestureRecognizerDelegate
    
    /// Only recognize outside tap if it's tapping the background
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let popupViewController = self.popupViewController else { return false }
        
        if gestureRecognizer === self.outsideTapGesture {
            return touch.view == popupViewController.view
        } else {
            return true
        }
    }
    
    /// Dismiss gesture should block scrolling and take over if there's a scrollView and it's scrolled to the top
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === self.outsideTapGesture { return true }
        
        if let scrollGesture = self.scrollGestureRecognizer, let scrollView = scrollGesture.view as? UIScrollView {
            return scrollView.contentOffset.y <= 0
        }
        
        return true
    }
    
    
    // MARK: - Gesture handlers
    
    @objc func handleOutsideTap() {
        self.popupViewController?.interactionControllerDidTapOutside(self)
    }
    
    @objc func handleDismissalGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
            case .began:
                self.isDragging = true
                self.dismissalGestureDidBegin(gesture)
                
            case .changed:
                self.dismissalGestureDidUpdate(gesture)
                
            case .ended, .cancelled:
                self.isDragging = false
                self.dismissalGestureDidEnd(gesture)
                
            default:
                break
        }
    }
    
}

// MARK: - Dismissal Interaction

private extension PopupStackInteractionController {
    
    func dismissalGestureDidBegin(_ gesture: UIPanGestureRecognizer) {
        //
    }
    
    func dismissalGestureDidUpdate(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        let translation = gesture.translation(in: view).y
        let interactionDistance = self.interationDistance(for: view)
        
        var progress = interactionDistance == 0 ? 0 : (translation / interactionDistance)
        if progress < 0 { progress /= (1.0 + abs(progress * 20)) }
        
        self.updateDismissalInteraction(progress: progress, interactionDistance: interactionDistance)
    }
    
    func dismissalGestureDidEnd(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        let translation = gesture.translation(in: view).y
        let velocity = gesture.velocity(in: view).y
        
        let interactionDistance = self.interationDistance(for: view)
        
        if velocity > 300 || (translation > (interactionDistance / 2) && velocity > -300) {
            
            // Dismiss
            
            let initialSpringVelocity = self.springVelocity(
                distanceToTravel: (interactionDistance - translation), gestureVelocity: velocity
            )
            
            self.commitDismissalInteraction(velocity: initialSpringVelocity, interactionDistance: interactionDistance)

        }
        else {
            
            // Reset
            
            let initialSpringVelocity = self.springVelocity(
                distanceToTravel: abs(translation), gestureVelocity: velocity
            )
            
            self.cancelDismissalInteraction(velocity: initialSpringVelocity)
            
        }
    }
    
    
    // MARK: - Animations
    
    func updateDismissalInteraction(progress: CGFloat, interactionDistance: CGFloat) {
        guard let popupViewController = self.popupViewController else { return }
        let containerViews = popupViewController.contentContainerViews
                
        for (i, view) in containerViews.enumerated() {
            if i == containerViews.count - 1 {
                
                view.transform = CGAffineTransform(translationX: 0, y: interactionDistance*progress)
            } else {
                if i == containerViews.count - 2 {
                    view.setDimmed(progress: 1 - progress)
                }
                view.transform = self.stackTransform(for: view, stackIndex: containerViews.count - i - 1, progress: progress)
            }
        }
        
        if containerViews.count == 1 {
            popupViewController.view.backgroundColor = UIColor.black.withAlphaComponent(popupViewController.dimAlpha * (1 - progress))
        }
    }
    
    func cancelDismissalInteraction(velocity: CGFloat) {
        guard let popupViewController = self.popupViewController else { return }
        let containerViews = popupViewController.contentContainerViews
        
        let timingParameters = UISpringTimingParameters(
            dampingRatio: 0.8,
            initialVelocity: CGVector(dx: 0, dy: velocity)
        )
        
        let animator = UIViewPropertyAnimator(duration: 0.5, timingParameters: timingParameters)
        
        animator.addAnimations {
            
            for (i, view) in containerViews.enumerated() {
                if i == containerViews.count - 1 {
                    view.transform = .identity
                } else {
                    if i == containerViews.count - 2 {
                        view.setDimmed(true)
                    }
                    view.transform = self.stackTransform(for: view, stackIndex: containerViews.count - i - 1, progress: 0)
                }
            }
            
            popupViewController.view.backgroundColor = UIColor.black.withAlphaComponent(popupViewController.dimAlpha)
            
        }
        
        animator.startAnimation()
    }
    
    func commitDismissalInteraction(velocity: CGFloat, interactionDistance: CGFloat) {
        guard let popupViewController = self.popupViewController else { return }
        let containerViews = popupViewController.contentContainerViews
        guard let containerView = containerViews.last else { return }
        
        
        popupViewController.interactionControllerWillCommitDismissal(self)
        
        let isDismissingEntirely = containerViews.count == 1
        
        let timingParameters = UISpringTimingParameters(
            dampingRatio: 0.8,
            initialVelocity: CGVector(dx: 0, dy: min(10, velocity))
        )
        
        let animator = UIViewPropertyAnimator(duration: 0.5, timingParameters: timingParameters)
        
        if isDismissingEntirely, let sourceAttributes = containerView.customSourceAttributes {
            let shadowAnim = CABasicAnimation(keyPath: "shadowOpacity")
            shadowAnim.fromValue = containerView.layer.shadowOpacity
            shadowAnim.toValue = sourceAttributes.view.layer.shadowOpacity
            shadowAnim.duration = 0.35
            containerView.layer.add(shadowAnim, forKey: nil)
            containerView.layer.shadowOpacity = sourceAttributes.view.layer.shadowOpacity
            
            let shadowRadiusAnim = CABasicAnimation(keyPath: "shadowRadius")
            shadowRadiusAnim.fromValue = containerView.layer.shadowRadius
            shadowRadiusAnim.toValue = sourceAttributes.view.layer.shadowRadius
            shadowRadiusAnim.duration = 0.35
            containerView.layer.add(shadowRadiusAnim, forKey: nil)
            containerView.layer.shadowRadius = sourceAttributes.view.layer.shadowRadius
            
            let shadowColorAnim = CABasicAnimation(keyPath: "shadowColor")
            shadowColorAnim.fromValue = containerView.layer.shadowColor
            shadowColorAnim.toValue = sourceAttributes.view.layer.shadowColor
            shadowColorAnim.duration = 0.35
            containerView.layer.add(shadowColorAnim, forKey: nil)
            containerView.layer.shadowColor = sourceAttributes.view.layer.shadowColor
            
            let cornerAnim = CABasicAnimation(keyPath: "cornerRadius")
            cornerAnim.fromValue = containerView.containerView.layer.cornerRadius
            cornerAnim.toValue = sourceAttributes.view.layer.cornerRadius
            cornerAnim.duration = 0.35
            containerView.containerView.layer.add(cornerAnim, forKey: nil)
            containerView.containerView.layer.cornerRadius = sourceAttributes.view.layer.cornerRadius
        }
        
        animator.addAnimations {
            for (i, view) in containerViews.enumerated() {
                if view === containerView {
                    
                    // If this is the last view in the stack and
                    // it has a custom source view, animate into
                    // the custom source view
                    if isDismissingEntirely, let sourceAttributes = containerView.customSourceAttributes {
                        sourceAttributes.view.alpha = 1
                        containerView.bounds.size = sourceAttributes.initialSize
                        containerView.center = sourceAttributes.initialPosition
                        containerView.setNeedsLayout()
                        containerView.layoutIfNeeded()
                        containerView.subviews.forEach {
                            $0.setNeedsLayout()
                            $0.layoutIfNeeded()
                        }
                        
                        containerView.transform = .identity
                        containerView.contentView.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
                    }
                    else {
                        view.transform = CGAffineTransform(translationX: 0, y: interactionDistance)
                    }
                }
                else {
                    if i == containerViews.count - 2 {
                        view.setDimmed(false)
                    }
                    view.transform = self.stackTransform(for: view, stackIndex: containerViews.count - i - 1, progress: 1)
                }
            }
            
            if isDismissingEntirely {
                popupViewController.view.backgroundColor = .clear
            }
            
        }
        
        animator.addCompletion { _ in
            popupViewController.interactionControllerDidCommitDismissal(self)
        }
        
        animator.startAnimation()
        
    }
    
}


// MARK: - Helpers

extension PopupStackInteractionController {
    
    /// Distance required for the view to be off screen
    func interationDistance(for view: UIView) -> CGFloat {
        guard let popupViewController = self.popupViewController else { return 0 }
        
        // If the view has a custom source position,
        // the interaction distance is from current center to that position
        // rather than the bottom of the screen
        if
            let view = view as? PopupStackViewController.ContentContainerView,
            let initialPosition = view.customSourceAttributes?.initialPosition
        {
            return initialPosition.y - view.center.y
        }
        
        let maxY = popupViewController.view.bounds.maxY
        let viewMinY = view.center.y - (view.bounds.height/2)
        return maxY - viewMinY
    }
    
    /// Returns the appropriate transform for a view in the stack
    /// Views further behind appear smaller
    /// stackIndex is ordered front to back, where 0 is the frontmost view in the stack
    func stackTransform(for view: UIView, stackIndex: Int, progress: CGFloat) -> CGAffineTransform {
        guard let popupVC = self.popupViewController else { return .identity }
        if stackIndex == 0 { return .identity }
        
        let scale: CGFloat
        
        if stackIndex == 1 {
            scale = 0.9 + (0.1 * progress)
        }
        else {
            scale = 0.84 + (0.06 * progress)
        }
        
        // Translate the view such that 12 pts are always visible
        
        let transformedHeight = view.bounds.height * scale
        let primaryHeight = popupVC.contentContainerViews[0].bounds.height
        let topHeightDiff = (primaryHeight - transformedHeight) / 2
        
        let maxTranslate = topHeightDiff + 12
        let translate = -maxTranslate + (maxTranslate * progress)
        
        return CGAffineTransform(scaleX: scale, y: scale).concatenating(CGAffineTransform(translationX: 0, y: translate))
    }
    
    func springVelocity(distanceToTravel: CGFloat, gestureVelocity: CGFloat) -> CGFloat {
        return distanceToTravel == 0 ? 0 : gestureVelocity / distanceToTravel
    }
    
}

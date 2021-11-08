//
//  IconPicker.swift
//  Timer
//
//  Created by Miles Vinson on 3/19/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import UIKit

class PickerAlertController: UIViewController, UIGestureRecognizerDelegate, UIPopoverPresentationControllerDelegate {
        
    
    public var isPopover: Bool {
        return UIApplication.shared.windows.first?.rootViewController?.traitCollection.horizontalSizeClass != .compact
    }
    
    private let dimView = UIView()
    
    private let outsideTap = UITapGestureRecognizer()
    
    /*
    Add custom views like date pickers to this view
     */
    public let contentView = UIView()

    /*
    Visibile background, rounded corners, has contentView in it
     */
    private let popupView = UIView()
    
    public var popupBackgroundColor: UIColor? {
        get {
            return popupView.backgroundColor
        }
        set {
            popupView.backgroundColor = newValue
        }
    }
    
    public let panGesture = UIPanGestureRecognizer()
    private let handleView = HandleView()
        
    public var closeCompletion: (()->Void)?
    
    public var showHandle: Bool {
        get {
            return handleView.isHidden == false
        }
        set {
            handleView.isHidden = !newValue
        }
    }
    
    public var contentHeight: CGFloat = 300
    public var contentWidth: CGFloat = 375
    public var contentOffset: CGFloat = 20
    
    /*
    The visible height of the popupView in sheet form, never fullscreen
     */
    private var visibleHeight: CGFloat = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeView()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        dimView.frame = self.view.bounds
        
        layoutContentView()
        
    }
    
    
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        
        setAdaptiveLayout()

        if isPopover {
            return .popover
        } else {
            return .overFullScreen
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        presentView()
        
    }
    
    func willOpen() {
        
    }
    
    func willClose() {
        
    }
    
    func didDrag(_ translation: CGFloat) {
        
    }
    
    func didExitWithoutConfirming() {
        
    }
    
    @objc private func outsideTapped() {
        willClose()
        didExitWithoutConfirming()
        close()
    }
    
    private var shouldDisableClose = false
    public func disablePanWithoutClosing() {
        shouldDisableClose = true
        panGesture.isEnabled = false
    }
    
    public func convertViewFrame(_ view: UIView) -> CGRect {
        return contentView.convert(view.frame, to: self.view)
    }
}

//MARK: Initialize
private extension PickerAlertController {
    func initializeView() {
        self.view.backgroundColor = .clear
        
        dimView.alpha = 0
        
        popupView.backgroundColor = Colors.foregroundColor
        self.view.addSubview(popupView)
        contentView.backgroundColor = .clear
        popupView.addSubview(contentView)
                
        
    }
    
    func setAdaptiveLayout() {
        if !isPopover {
            dimView.backgroundColor = Colors.dimColor
            self.view.insertSubview(dimView, at: 0)
            
            outsideTap.delegate = self
            outsideTap.addTarget(self, action: #selector(outsideTapped))
            dimView.addGestureRecognizer(outsideTap)
            
            popupView.addGestureRecognizer(panGesture)
            panGesture.addTarget(self, action: #selector(didPanContentView(_:)))
            
            popupView.addSubview(handleView)
        }
        else {
            dimView.removeFromSuperview()
            dimView.removeGestureRecognizer(outsideTap)
            popupView.removeGestureRecognizer(panGesture)
            handleView.removeFromSuperview()
        }
    }
}

//MARK: Layouts
private extension PickerAlertController {
    
    func layoutContentView() {
        
        if isPopover {
            
            self.preferredContentSize = CGSize(
                width: contentWidth + view.safeAreaInsets.left + view.safeAreaInsets.right,
                height: contentHeight + 10)
            
            popupView.frame = self.view.bounds
            
            contentView.frame = popupView.bounds.inset(by: self.view.safeAreaInsets).inset(by: UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0))
            contentView.roundCorners(0)
            
            return
        }
        
        let maxY = view.bounds.maxY
        
        let contentHeight = self.contentHeight + contentOffset
        let minY = maxY - contentHeight - self.view.safeAreaInsets.bottom
        let rect = CGRect(
            x: 0,
            y: minY,
            width: self.view.bounds.width,
            height: contentHeight + 500
        )
        
        self.visibleHeight = contentHeight
        
        popupView.center = CGPoint(x: rect.midX, y: rect.midY)
        popupView.bounds.size = rect.size
        
        contentView.frame = CGRect(
            origin: CGPoint(x: 0, y: contentOffset),
            size: CGSize(
                width: popupView.bounds.width,
                height: self.contentHeight)
        )
        
        popupView.roundCorners(25)
        contentView.roundCorners(25)
        
        handleView.frame = CGRect(x: 0, y: 0, width: popupView.bounds.width, height: 20)
        
    }
    
}

//MARK: Private methods
private extension PickerAlertController {
    
    @objc func didPanContentView(_ sender: UIPanGestureRecognizer) {
        
        if sender.state == .began {
            self.willClose()
        }
        else if sender.state == .changed {
            gestureDidUpdate(sender)
        }
        else {
            gestureDidEnd(sender)
        }
    }
    
    func presentView() {
        
        if !isPopover {
            
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            
            popupView.transform = CGAffineTransform(translationX: 0, y: visibleHeight)
            
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
                
                self.dimView.alpha = 1
                
                self.popupView.transform = .identity
                
                
            }, completion: nil)
        }
    }

    func gestureDidUpdate(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        let translation = gesture.translation(in: view).y
        let interactionDistance = self.interactionDistance()
        
        var progress = interactionDistance == 0 ? 0 : (translation / interactionDistance)
        if progress < 0 { progress /= (1.0 + abs(progress * 15)) }
        
        popupView.transform = CGAffineTransform(translationX: 0, y: progress*interactionDistance)
        self.dimView.alpha = 1 - progress
    }
    
    func gestureDidEnd(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        let translation = gesture.translation(in: view).y
        let velocity = gesture.velocity(in: view).y
        
        let interactionDistance = self.interactionDistance()
       
        if velocity > 300 || (translation > (interactionDistance / 2) && velocity > -300) {
            
            // Dismiss
            
            let initialSpringVelocity = self.springVelocity(
                distanceToTravel: (interactionDistance - translation),
                gestureVelocity: velocity
            )
            
            self.commitDismissalInteraction(velocity: initialSpringVelocity, interactionDistance: interactionDistance)

        }
        else {
            
            // Reset
            
            let initialSpringVelocity = self.springVelocity(
                distanceToTravel: translation,
                gestureVelocity: velocity
            )
            
            self.cancelDismissalInteraction(velocity: initialSpringVelocity)
            
        }
    }
    
    func commitDismissalInteraction(velocity: CGFloat, interactionDistance: CGFloat) {
        let timingParameters = UISpringTimingParameters(
            dampingRatio: 0.8,
            initialVelocity: CGVector(dx: 0, dy: velocity)
        )
        
        let animator = UIViewPropertyAnimator(duration: 0.4, timingParameters: timingParameters)
        
        animator.addAnimations {
            self.popupView.transform = CGAffineTransform(translationX: 0, y: interactionDistance)
            self.dimView.alpha = 0
        }
        
        animator.addCompletion { _ in
            self.dismiss(animated: false, completion: {
                self.closeCompletion?()
            })
        }
        
        animator.startAnimation()
    }
    
    func cancelDismissalInteraction(velocity: CGFloat) {
        let timingParameters = UISpringTimingParameters(
            dampingRatio: 0.8,
            initialVelocity: CGVector(dx: 0, dy: velocity)
        )
        
        let animator = UIViewPropertyAnimator(duration: 0.4, timingParameters: timingParameters)
        
        animator.addAnimations {
            self.popupView.transform = .identity
            self.dimView.alpha = 1
        }
        
        animator.startAnimation()
    }
    
    private func interactionDistance() -> CGFloat {
        return contentView.bounds.height + 50
    }
    
    func springVelocity(distanceToTravel: CGFloat, gestureVelocity: CGFloat) -> CGFloat {
        return distanceToTravel == 0 ? 0 : gestureVelocity / distanceToTravel
    }
    
}

//MARK: Public methods
extension PickerAlertController {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == outsideTap {
            return dimView == touch.view
        }
        
        return true
    }
    
    @objc func close() {
        if isPopover {
            self.dismiss(animated: true, completion: self.closeCompletion)
        }
        else {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut], animations: {
                self.popupView.transform = CGAffineTransform(translationX: 0, y: self.visibleHeight + 20)
                self.dimView.alpha = 0
            }) { (complete) in
                self.dismiss(animated: false, completion: {
                    self.closeCompletion?()
                })
            }
        }
        
    }
    
    
}

extension UIViewController {
    func presentAlert(_ alert: PickerAlertController, sourceView: UIView? = nil, sourceRect: CGRect? = nil, arrowDirection: UIPopoverArrowDirection = .any) {
        
        alert.modalPresentationStyle = .popover
        alert.popoverPresentationController?.sourceView = sourceView
        if let rect = sourceRect {
            alert.popoverPresentationController?.sourceRect = rect
        }
        alert.popoverPresentationController?.permittedArrowDirections = arrowDirection
        alert.popoverPresentationController?.delegate = alert
        alert.modalPresentationCapturesStatusBarAppearance = false
        
        self.present(alert, animated: false, completion: nil)
        
    }
}

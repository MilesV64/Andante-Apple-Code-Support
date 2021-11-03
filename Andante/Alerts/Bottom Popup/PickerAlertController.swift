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
    Visibile background, rounded corners, has componentView in it
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
    
    /**
        If false, extends component view beyond safe area margins.
     */
    public var useSafeArea = true
    
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
    
    public var isFullscreenEnabled = false
    private var isFullscreen = false
    
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
        
        layoutComponentView()
                
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
    
    func gestureDidBegin(_ gesture: UIPanGestureRecognizer) {
        
    }
    
    func gestureDidEnd(_ gesture: UIPanGestureRecognizer) {
        if shouldDisableClose {
            shouldDisableClose = false
            return
        }
        
        var shouldOpen = false
        
        if !isFullscreenEnabled || isFullscreen == false {
            if gesture.translation(in: popupView).y > visibleHeight*0.6 ||
                (gesture.velocity(in: popupView).y > 40 && gesture.translation(in: popupView).y >= 0) {
                
                self.didExitWithoutConfirming()
                
                UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
                    self.popupView.transform = CGAffineTransform(translationX: 0, y: self.visibleHeight + 50)
                    self.dimView.alpha = 0
                    
                }) { (complete) in
                    self.dismiss(animated: false, completion: {
                        self.closeCompletion?()
                    })
                }
                
            }
            else if isFullscreenEnabled && (gesture.translation(in: popupView).y < -30 ||
                (gesture.velocity(in: popupView).y < -40 && gesture.translation(in: popupView).y <= 0)) {
                
                let newMinY = self.view.safeAreaInsets.top
                let currentMinY = (self.view.bounds.maxY - visibleHeight) + popupView.transform.ty
                
                popupView.transform = CGAffineTransform(translationX: 0, y: currentMinY - newMinY)
                
                self.isFullscreen = true
                
                shouldOpen = true
            }
            else {
                shouldOpen = true
            }
        }
        else if isFullscreenEnabled && isFullscreen {
            let sheetMinY = self.view.bounds.maxY - visibleHeight
            let currentMinY = self.view.safeAreaInsets.top + popupView.transform.ty
            
            if currentMinY > self.view.bounds.maxY - visibleHeight*0.6 {
                UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
                    self.popupView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
                    self.dimView.alpha = 0
                    
                }) { (complete) in
                    self.dismiss(animated: false, completion: {
                        self.closeCompletion?()
                    })
                }
            }
            else if currentMinY > sheetMinY*0.6 {
                isFullscreen = false
                popupView.transform = CGAffineTransform(translationX: 0, y: currentMinY - sheetMinY - 20)
                
                shouldOpen = true
            }
            else {
                shouldOpen = true
            }
        }
        
        if shouldOpen {
            willOpen()
            UIView.animate(withDuration: 0.55, delay: 0, usingSpringWithDamping: 0.84, initialSpringVelocity: 0, options: [.curveEaseOut], animations: {
                
                self.dimView.alpha = 1
                self.popupView.transform = .identity
                
                
            }, completion: nil)
        }
        
    }
    
    func gestureDidChange(_ gesture: UIPanGestureRecognizer) {
        var translation = gesture.translation(in: popupView).y
        
        if translation < 0 {
            let t = -translation
            
            let alpha: CGFloat = 0.015
            translation = -(1 - exp(-alpha*t))/alpha
        }
        
        let sheetMinY = self.view.bounds.height - visibleHeight
        let actualMinY = (isFullscreen ? self.view.safeAreaInsets.top : sheetMinY) + popupView.transform.ty
        let actualVisibleHeight = self.view.bounds.maxY - actualMinY
        
        let phase = actualVisibleHeight / visibleHeight
        self.dimView.alpha = phase
        popupView.transform = CGAffineTransform(translationX: 0, y: translation)
            
        didDrag(translation)
            
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
            
            return
        }
        
        let maxY = UIScreen.main.bounds.maxY
        
        let contentHeight = self.contentHeight + contentOffset
        let minY = isFullscreen ? self.view.safeAreaInsets.top : (maxY - contentHeight - self.view.safeAreaInsets.bottom)
        let rect = CGRect(
            x: 10,
            y: max(self.view.safeAreaInsets.top, minY),
            width: self.view.bounds.width - 20,
            height: contentHeight
        )
        
        self.visibleHeight = contentHeight
        
        popupView.center = CGPoint(x: rect.midX, y: rect.midY)
        popupView.bounds.size = rect.size
        popupView.roundCorners(25)
        
        handleView.frame = CGRect(x: 0, y: 0, width: popupView.bounds.width, height: 20)
        
    }
    
    func layoutComponentView() {
        if isPopover {
            contentView.roundCorners(0, prefersContinuous: true)
            return
        }
        
        let minY = contentOffset
        contentView.roundCorners(25, prefersContinuous: true)
        contentView.clipsToBounds = true
        contentView.frame = CGRect(
            origin: CGPoint(x: 0, y: minY),
            size: CGSize(
                width: popupView.bounds.width,
                height: self.contentHeight))
    }
    
}

//MARK: Private methods
private extension PickerAlertController {
    
    @objc func didPanContentView(_ sender: UIPanGestureRecognizer) {
        
        if sender.state == .began {
            gestureDidBegin(sender)
        }
        else if sender.state == .changed {
            gestureDidChange(sender)
        }
        else {
            gestureDidEnd(sender)
        }
    }
    
    func presentView() {
        
        if !isPopover {
            self.viewDidLayoutSubviews()
            popupView.transform = CGAffineTransform(translationX: 0, y: visibleHeight)
            
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
                
                self.dimView.alpha = 1
                
                self.popupView.transform = .identity
                
                
            }, completion: nil)
        }
        
        
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

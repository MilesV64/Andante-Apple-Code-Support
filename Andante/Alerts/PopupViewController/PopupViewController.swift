//
//  PopupViewController.swift
//  Andante
//
//  Created by Miles Vinson on 2/18/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit
import Combine

class PopupViewController: UIViewController, UIGestureRecognizerDelegate {
    
    public var sourceView: UIView?
    public var minXConstraint: CGFloat?
    public var maxXConstraint: CGFloat?
    
    private let outsideTap = UITapGestureRecognizer()
    public let panGesture = UIPanGestureRecognizer()
    
    public var contentView = PopupContentView()

    private let dimView = UIView()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    private let bgView = UIView()
    private var bottomView: UIView?
    
    private var handleView: HandleView?
    
    private var widthBreakpt: CGFloat = 428
    
    public var contentFrame: CGRect {
        return bgView.frame
    }
    
    public var topInset: CGFloat {
        return bgView.bounds.height - contentView.bounds.height
    }
    
    public var contentWidth: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return view.bounds.width
        } else {
            return min(375, view.bounds.width)
        }
        
    }
    
    public var preferredContentHeight: CGFloat = 375
    private var contentHeight: CGFloat = 375
    
    public var layout: UIUserInterfaceSizeClass {
        return (view.window ?? view).bounds.width > widthBreakpt ? .regular : .compact
    }
    
    
    
    public var closeCompletion: (()->())?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        self.modalPresentationStyle = .overFullScreen
        self.modalPresentationCapturesStatusBarAppearance = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    
        let contentInset = layout == .compact ? self.view.safeAreaInsets : nil
        contentView.setSafeArea(contentInset)
        
        dimView.frame = view.bounds
        
        setResponsiveLayout()
        
        layoutBGView()
        
        bgView.layer.shadowPath = UIBezierPath(roundedRect: bgView.bounds, cornerRadius: bgView.layer.cornerRadius).cgPath
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        setBGShadow()
        
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == outsideTap {
            return dimView == touch.view
        }
        
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        presentView()
        
    }
    
    public func willDrag() {
        
    }
    
    public func willClose() {
        
    }
    
    
    private var shouldDisableClose = false
    public func disablePanWithoutClosing() {
        shouldDisableClose = true
        panGesture.isEnabled = false
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private var keyboardFrame: CGRect = .zero
    
    @objc func adjustForKeyboard(_ notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        guard let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            print("Couldn't get animation duration")
            return
        }

        guard let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            print("Couldn't get animation curve")
            return
        }
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            keyboardFrame = .zero
        } else {
            keyboardFrame = keyboardViewEndFrame
        }
        
        UIView.animate(
            withDuration: animationDuration,
            delay: 0.0,
            options: UIView.AnimationOptions(rawValue: curve),
            animations: {
                
                self.layoutBGView()
                
            },
            completion: nil)
        
        
    }
    
    public func layoutBGView(animateContent: Bool = true) {
        
        if layout == .compact {
            bgView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            
            contentHeight = min(preferredContentHeight, view.bounds.height * 0.8)
            
            let handleSpace: CGFloat = 20
            let height: CGFloat
            let maxY: CGFloat
            
            if keyboardFrame != .zero {
                height = contentHeight + handleSpace
                maxY = keyboardFrame.minY
            } else {
                height = contentHeight + handleSpace + view.safeAreaInsets.bottom
                maxY = view.bounds.maxY
            }
            
            bgView.contextualFrame = CGRect(
                x: view.bounds.midX - contentWidth/2,
                y: maxY - height,
                width: contentWidth,
                height: height
            )
            
            bottomView?.frame = CGRect(
                x: 0, y: bgView.bounds.maxY - 4,
                width: bgView.bounds.width,
                height: 300)
            
            handleView?.frame = CGRect(x: 0, y: 0, width: bgView.bounds.width, height: handleSpace)
            
            if !animateContent {
                UIView.performWithoutAnimation {
                    self.contentView.contextualFrame = self.bgView.bounds.inset(
                        by: UIEdgeInsets(top: handleSpace, left: 0, bottom: 0, right: 0))
                }
            }
            else {
                contentView.contextualFrame = bgView.bounds.inset(by: UIEdgeInsets(top: handleSpace, left: 0, bottom: 0, right: 0))
            }
            
//            blurView.frame = CGRect(x: 0, y: 0, width: bgView.bounds.width, height: bgView.bounds.height + 600)
            
        }
        else if let sourceView = sourceView {
            let relativePoint = sourceView.convert(sourceView.bounds, to: self.view).center

            let minY = relativePoint.y - 16
            
            let space = (view.bounds.height - minY) - 100
            contentHeight = min(preferredContentHeight, space)
            
            bgView.bounds.size = CGSize(width: contentWidth, height: contentHeight + 8)

            let minX = minXConstraint ?? Constants.smallMargin/2
            let maxX = (maxXConstraint ?? self.view.bounds.maxX - Constants.smallMargin/2) - bgView.bounds.width
            let x = clamp(value: relativePoint.x - bgView.bounds.width/2, min: minX, max: maxX)
                        
            let convPoint = CGPoint(
                x: relativePoint.x - x,
                y: 0)
            
            bgView.layer.anchorPoint = CGPoint(x: convPoint.x/bgView.bounds.width, y: convPoint.y/bgView.bounds.height)
            
            bgView.center = CGPoint(
                x: relativePoint.x,
                y: minY)
            
            contentView.contextualFrame = bgView.bounds.inset(by: UIEdgeInsets(t: 8))
            
            blurView.frame = bgView.bounds

        }
        else {
            let space = view.bounds.height - 100
            contentHeight = min(preferredContentHeight, space)
            
            bgView.bounds.size = CGSize(width: contentWidth, height: contentHeight)
            bgView.center = view.bounds.center
            contentView.contextualFrame = bgView.bounds
            
            blurView.frame = bgView.bounds

        }
        
        
    }
}

//MARK: - Initial Setup
extension PopupViewController {
    
    private func setupUI() {
        self.view.backgroundColor = .clear
        
        dimView.backgroundColor = Colors.dimColor
        dimView.alpha = 0
        view.addSubview(dimView)
        
        setupBGView()
        
        outsideTap.delegate = self
        outsideTap.addTarget(self, action: #selector(close))
        dimView.addGestureRecognizer(outsideTap)
        
        sourceView?.publisher(for: \.frame, options: .new).sink {
            [weak self] _ in
            guard let self = self else { return }
            if self.layout == .regular {
                self.view.setNeedsLayout()
            }
        }.store(in: &cancellables)
        
    }
    
    private func setupBGView() {
        bgView.backgroundColor = Colors.foregroundColor
        
//        blurView.contentView.backgroundColor = Colors.dynamicColor(
//            light: Colors.foregroundColor.withAlphaComponent(0.75),
//            dark: Colors.foregroundColor.withAlphaComponent(0.7))
//        bgView.addSubview(blurView)
        
        blurView.clipsToBounds = true
         
        bgView.clipsToBounds = false
        
        contentView.backgroundColor = .clear
        bgView.addSubview(contentView)
        
        view.addSubview(bgView)

    }
    
}

//MARK: - Layouts
extension PopupViewController {
    
    private func setResponsiveLayout() {
        
        if layout == .regular {
            setRegularLayout()
        } else {
            setCompactLayout()
        }
        
    }
    
    private func setCompactLayout() {
        if handleView == nil {
            handleView = HandleView()
            bgView.addSubview(handleView!)
            
            bottomView = UIView()
            bottomView?.backgroundColor = Colors.foregroundColor
            bgView.addSubview(bottomView!)

        }
        
        blurView.roundCorners(25)
        bgView.roundCorners(25)
        
        blurView.layer.maskedCorners = [
            .layerMaxXMinYCorner, .layerMinXMinYCorner
        ]
        
        bgView.layer.maskedCorners = [
            .layerMaxXMinYCorner, .layerMinXMinYCorner
        ]
        
        dimView.backgroundColor = Colors.dimColor
        setBGShadow()
        
        bgView.addGestureRecognizer(panGesture)
        panGesture.addTarget(self, action: #selector(didPanContentView(_:)))
    }
    
    private func setRegularLayout() {
        if handleView != nil {
            handleView?.removeFromSuperview()
            handleView = nil
            
            bottomView?.removeFromSuperview()
            bottomView = nil
        }
        
        blurView.roundCorners(12)
        bgView.roundCorners(12)
        
        blurView.layer.maskedCorners = [
            .layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner
        ]
        
        bgView.layer.maskedCorners = [
            .layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner
        ]
        
        dimView.backgroundColor = Colors.lighterDimColor
        setBGShadow()
        
        bgView.removeGestureRecognizer(panGesture)
        
    }
    
    private func setBGShadow() {
        if layout == .compact {
            bgView.layer.shadowOpacity = 0
        } else {
            if traitCollection.userInterfaceStyle == .dark {
                bgView.setShadow(radius: 40, yOffset: 10, opacity: 0.26, color: .black)
            }
            else {
                bgView.setShadow(radius: 40, yOffset: 10, opacity: 0.18, color: Colors.barShadowColor.toColor(.black, percentage: 70))
            }
        }
    }
    
    
    
}


//MARK: - Pan Gesture
private extension PopupViewController {
    
    @objc func didPanContentView(_ sender: UIPanGestureRecognizer) {
        
        if sender.state == .began {
            gestureDidBegin(sender)
        }
        else if sender.state == .changed {
            gestureDidChange(sender)
        }
        else {
            if shouldDisableClose {
                shouldDisableClose = false
            } else {
                gestureDidEnd(sender)
            }
        }
    }
    
    func gestureDidBegin(_ gesture: UIPanGestureRecognizer) {
        willDrag()
    }
    
    func gestureDidEnd(_ gesture: UIPanGestureRecognizer) {

        let height = bgView.bounds.height
        
        if gesture.translation(in: bgView).y > height*0.6 ||
            (gesture.velocity(in: bgView).y > 40 && gesture.translation(in: bgView).y >= 0) {
            
            let originalVelocity = gesture.velocity(in: self.view).x
            let progress = getGesturePhase(gesture)
            var velocity: CGFloat = 0
            if originalVelocity > 0 {
                velocity = originalVelocity / ((1-progress)*bgView.bounds.height)
            }
            else if originalVelocity < 0 {
                velocity = originalVelocity / ((progress)*bgView.bounds.height)
            }
            
            if velocity > 2 {
                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: velocity*2, options: .curveLinear, animations: {
                    self.bgView.transform = CGAffineTransform(translationX: 0, y: height + 50)
                    self.dimView.alpha = 0
                }, completion: { complete in
                    self.dismiss(animated: false, completion: {
                        self.closeCompletion?()
                    })
                })
                
            }
            else {
                UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
                    self.bgView.transform = CGAffineTransform(translationX: 0, y: height + 50)
                    self.dimView.alpha = 0
                    
                }) { (complete) in
                    self.dismiss(animated: false, completion: {
                        self.closeCompletion?()
                    })
                }
            }
                
            
        }
        else {
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.84, initialSpringVelocity: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
                
                self.dimView.alpha = 1
                self.bgView.transform = .identity
                
            }, completion: nil)
        }
        
    }
    
    func gestureDidChange(_ gesture: UIPanGestureRecognizer) {
        var translation = gesture.translation(in: bgView).y
        let height = bgView.bounds.height
        
        if translation < 0 {
            let t = -translation
            
            let alpha: CGFloat = 0.015
            translation = -(1 - exp(-alpha*t))/alpha
        }
        
        bgView.transform = CGAffineTransform(translationX: 0, y: translation)
        
        let minY = (bgView.center.y - bgView.bounds.height/2) + bgView.transform.ty
        let visibleHeight = self.view.bounds.maxY - minY
        
        let phase = visibleHeight / height
        self.dimView.alpha = phase
            
    }
    
    private func getGesturePhase(_ gesture: UIPanGestureRecognizer) -> CGFloat {
        let height = bgView.bounds.height
        
        let minY = (bgView.center.y - bgView.bounds.height/2) + bgView.transform.ty
        let visibleHeight = self.view.bounds.maxY - minY
        
        return visibleHeight / height
    }
    
}

//MARK: - Present/Dismiss
extension PopupViewController {
    
    func presentView() {
        viewDidLayoutSubviews()

        if layout == .compact {
            bgView.transform = CGAffineTransform(
                translationX: 0,
                y: bgView.bounds.height + max(10, view.safeAreaInsets.bottom) + 6)
            
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
                
                self.dimView.alpha = 1
                self.bgView.transform = .identity
                
            }, completion: nil)
        }
        else {
            bgView.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
            bgView.alpha = 0
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
                
                self.dimView.alpha = 1
                self.bgView.alpha = 1
                self.bgView.transform = .identity
                
            }, completion: nil)
        }
        
        
    }
    
    @objc func close() {
        
        willClose()
        
        if layout == .compact {
            let bottomSpace: CGFloat = max(10, self.view.safeAreaInsets.bottom) + 6
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut], animations: {
                self.bgView.transform = CGAffineTransform(
                    translationX: 0,
                    y: self.bgView.bounds.height + bottomSpace)
                self.dimView.alpha = 0
            }) { (complete) in
                self.dismiss(animated: false, completion: {
                    self.closeCompletion?()
                })
            }
        }
        else {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut], animations: {
                if self.sourceView == nil {
                    self.bgView.transform = CGAffineTransform(
                        scaleX: 0.86, y: 0.86)
                } else {
                    self.bgView.transform = CGAffineTransform(
                        scaleX: 0.7, y: 0.7)
                }
                
                self.dimView.alpha = 0
                self.bgView.alpha = 0
            }) { (complete) in
                self.dismiss(animated: false, completion: {
                    self.closeCompletion?()
                })
            }
        }
        
    }
    
    
}

extension UIViewController {
    func presentPopupViewController(_ viewController: PopupViewController) {
        self.present(viewController, animated: false, completion: nil)
    }
}

//
//  PopupStackViewController.swift
//  Andante
//
//  Created by Miles on 10/29/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

// PopupViewController is implemented as a child view controller rather than
// modal so it doesn't interfere with keyboards.

class PopupStackViewController: UIViewController, KeyboardObserver, PopupStackInteractionControllerDelegate {
    
    // A container for the PopupStackContentView.
    // Handles clipping, shadow, handleView, and an optional
    // source view used for custom presentation transitions.
    class ContentContainerView: UIView {
        
        static let handleSpace: CGFloat = 32
        
        /// Contains the `contentView`, clipping it to ensure the contentView
        /// doesn't go past the edges of the view.
        let containerView = UIView()
        
        /// A dimming view added on top of everything for use
        /// during transitions
        private let dimView = UIView()
        
        /// An optional handle view. Used if the `contentView` returns `true`
        /// for `prefersHandleVisible`.
        private var handleView: UIView?
        
        /// The content view
        public var contentView: PopupStackContentView {
            didSet {
                self.containerView.insertSubview(self.contentView, belowSubview: self.dimView)
            }
        }
        
        /// Explicitly set contentSize so the contentView is always the right size
        public var contentSize: CGSize = .zero
        
        struct CustomSourceAttributes {
            let view: UIView
            let initialSize: CGSize
            let initialPosition: CGPoint
        }
        
        private(set) var customSourceAttributes: CustomSourceAttributes?
        
        /// Adds the custom view to the container view, sizing it along with the container's size.
        /// The `finalSize` is used to make sure the `contentView` is layed out with
        /// the proper size regardless of the size of the overall view during the transition.
        public func setCustomSourceView(_ view: UIView, finalSize: CGSize) {
            self.addSubview(view)
            view.isUserInteractionEnabled = false
            self.customSourceAttributes = CustomSourceAttributes(
                view: view,
                initialSize: view.bounds.size,
                initialPosition: view.center
            )
        }
        
        init(contentView: PopupStackContentView) {
            self.contentView = contentView
            super.init(frame: .zero)
            
            self.backgroundColor = Colors.foregroundColor
            
            self.layer.shadowOpacity = 0.1
            self.layer.shadowOffset = CGSize(width: 0, height: 2)
            self.layer.shadowRadius = 9
            self.layer.shadowColor = UIColor.black.cgColor
            
            self.layer.cornerCurve = .continuous
            self.layer.cornerRadius = 25
                
            self.containerView.clipsToBounds = true
            self.containerView.layer.cornerCurve = .continuous
            self.containerView.layer.cornerRadius = 25
            
            self.containerView.addSubview(contentView)
            self.addSubview(self.containerView)
            
            self.dimView.backgroundColor = Colors.text.withAlphaComponent(0.04)
            self.dimView.alpha = 0
            self.dimView.isUserInteractionEnabled = false
            self.containerView.addSubview(self.dimView)
            
            self.addSubview(self.containerView)
            
            if contentView.prefersHandleVisible {
                let handleView = UIView()
                handleView.backgroundColor = Colors.lightBackground.withAlphaComponent(0.18)
                self.handleView = handleView
                self.containerView.addSubview(handleView)
            }
            
        }
        
        public func setDimmed(_ dimmed: Bool) {
            self.dimView.alpha = dimmed ? 1 : 0
        }
        
        public func setDimmed(progress: CGFloat) {
            self.dimView.alpha = progress
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.containerView.bounds.size = self.bounds.size
            self.containerView.center = self.bounds.center
            
            self.dimView.bounds.size = self.bounds.size
            self.dimView.center = self.bounds.center
            
            if let attributes = self.customSourceAttributes {
                if attributes.view.superview == self {
                    attributes.view.bounds.size = self.bounds.size
                    attributes.view.center = self.bounds.center
                }
            }
            
            self.contentView.bounds.size = self.contentSize
            self.contentView.center = self.bounds.center
            
            if let handleView = self.handleView {
                handleView.frame = CGRect(
                    x: self.bounds.midX - 17, y: 14,
                    width: 34, height: 4)
            }
            
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
     var dimAlpha: CGFloat {
        return self.traitCollection.userInterfaceStyle == .dark ? 0.28 : 0.12
    }

    /// The stack of content views, ordered back to front
    /// Use `push(_:)` to show a new content view, and `pop()` to remove the current content view.
    public var contentViews: [PopupStackContentView] {
        return self.contentContainerViews.map { $0.contentView }
    }
    
    private(set) var contentContainerViews: [ContentContainerView] = []
    
    
    // - Callbacks
    
    /// Called when the view will be dismissed, before any animations
    public var willDismiss: (() -> ())?
    
    /// Called when the view has been dismissed, after any animations
    public var didDismiss: (() -> ())?
    
    enum KeyboardBehavior {
        
        /// The content is positioned directly above the keyboard
        case clampToKeyboard
        
        /// the content is positioned at the top of the screen
        case clampToTop
    }
    
    public var keyboardBehavior: KeyboardBehavior = .clampToKeyboard
    
    private var shouldAnimateKeyboardOpen = true
    
    private let interactionController = PopupStackInteractionController()
    
    private var keyboardHeight: CGFloat = 0
    
    init(_ contentView: PopupStackContentView) {
        super.init(nibName: nil, bundle: nil)
        
        self.view.backgroundColor = .clear
        
        KeyboardManager.shared.addObserver(self)
        
        contentView.popupViewController = self
                
        let containerView = ContentContainerView(contentView: contentView)
        self.view.addSubview(containerView)
        self.contentContainerViews.append(containerView)
        
        self.interactionController.popupViewController = self
        self.interactionController.didChangePrimaryContentView(containerView)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func keyboardWillUpdate(_ keyboardManager: KeyboardManager, update: KeyboardManager.KeyboardUpdate) {
        self.keyboardHeight = keyboardManager.keyboardHeight
        
        if update == .show, self.shouldAnimateKeyboardOpen, !self.interactionController.isDragging {
            return
        }
        
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut]) {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
        
    }
    
    // TODO: Clamp height to visible space, taking into account the keyboard
    private func contentSize(for contentView: PopupStackContentView) -> CGSize {
        let width: CGFloat
        if self.traitCollection.horizontalSizeClass == .compact {
            width = self.view.bounds.width - 20
        } else {
            width = min(self.view.bounds.width - 20, 440)
        }
        
        return CGSize(
            width: width,
            height: contentView.preferredHeight(for: width)
        )
    }
    
    
    
    // MARK: - Layout
    
    /// During custom transitions, we don't want the standard layout in
    /// `viewDidLayoutSubviews`, so we block it with this flag.
    private var shouldBlockLayout = false
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !self.shouldBlockLayout, !self.interactionController.isDragging else { return }
        
        for containerView in self.contentContainerViews {
            let contentSize = self.contentSize(for: containerView.contentView)
            containerView.bounds.size = CGSize(
                width: contentSize.width,
                height: contentSize.height
            )
            
            if self.keyboardHeight == 0 {
                let bottomSafeArea = max(self.view.safeAreaInsets.bottom, 10)
                containerView.center = CGPoint(
                    x: self.view.bounds.midX,
                    y: self.view.bounds.maxY - bottomSafeArea - (contentSize.height/2))
            }
            else {
                if self.keyboardBehavior == .clampToKeyboard {
                    containerView.center = CGPoint(
                        x: self.view.bounds.midX,
                        y: self.view.bounds.maxY - self.keyboardHeight - (contentSize.height/2) - 10)
                }
                else {
                    containerView.center = CGPoint(
                        x: self.view.bounds.midX,
                        y: self.view.safeAreaInsets.top + 24 + (contentSize.height/2))
                }
            }
        }
        
    }
    
    /// Call when you want to adjust the height of the view, after setting a contentView's `preferredHeight` method
    public func reloadContentSize(animationDuration: TimeInterval = 0.35, completion: (() -> ())? = nil) {
        UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: [.allowUserInteraction, .beginFromCurrentState],
            animations: {
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }, completion: { _ in
                completion?()
            })
    }
    
    // MARK: - Show/Hide
    
    /// Presents the popup
    /// - Parameter customSourceView: If supplied, the popup animates from the size and position of the view rather than from the bottom of the screen.
    fileprivate func show(customSourceView: UIView? = nil, animationDuration: TimeInterval = 0.5) {
        guard let containerView = self.contentContainerViews.last else { return }
        let contentView = containerView.contentView
        
        self.shouldAnimateKeyboardOpen = false
        
        containerView.contentSize = self.contentSize(for: contentView)
        
        if let customSourceView = customSourceView {
            self.shouldBlockLayout = true

            // Set container to size and position of the custom view
            containerView.bounds.size = customSourceView.bounds.size
            containerView.center = customSourceView.center
            
            // Add the custom view to the container so it looks like
            // the custom view is morphing into the container
            containerView.setCustomSourceView(
                customSourceView,
                finalSize: self.contentSize(for: contentView)
            )
            
            // Start the content view with a smaller scale so it looks more natural
            // as the view expands
            contentView.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
            
            containerView.setNeedsLayout()
            containerView.layoutIfNeeded()
            
            UIView.animate(withDuration: animationDuration * 0.35) {
                customSourceView.alpha = 0
            }
        }
        else {
            // No custom view; open from the bottom of the screen
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            
            containerView.transform = CGAffineTransform(
                translationX: 0,
                y: contentView.preferredHeight(for: self.view.bounds.width) + 50
            )
        }
        
        self.interactionController.didChangePrimaryContentView(containerView)
                        
        contentView.willAppear()
        
        UIView.animate(withDuration: 0.15) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(self.dimAlpha)
        }
        
        UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            usingSpringWithDamping: 0.92,
            initialSpringVelocity: 0,
            options: [.allowUserInteraction, .beginFromCurrentState],
            animations: {
                self.shouldBlockLayout = false
                containerView.transform = .identity
                contentView.transform = .identity
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
                containerView.setNeedsLayout()
                containerView.layoutIfNeeded()
            }, completion: { _ in
                self.contentViews.last?.didAppear()
                self.shouldAnimateKeyboardOpen = true
            })
    }
    
    /// Hides the popup
    public func hide(completion: (() -> ())? = nil) {
        guard let containerView = self.contentContainerViews.last else { return }

        let timingParameters: UITimingCurveProvider
        
        if let sourceAttributes = containerView.customSourceAttributes {
            self.shouldBlockLayout = true
            timingParameters = UISpringTimingParameters(dampingRatio: 0.9)
            
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
        else {
            timingParameters = UISpringTimingParameters(dampingRatio: 1)
        }
        
        self.contentViews.forEach { $0.willDisappear() }
        self.willDismiss?()
        
        let animator = UIViewPropertyAnimator(duration: 0.5, timingParameters: timingParameters)
        
        animator.addAnimations {
            
            self.view.backgroundColor = .clear
            
            if let sourceAttributes = containerView.customSourceAttributes {
                sourceAttributes.view.alpha = 1
                containerView.bounds.size = sourceAttributes.initialSize
                containerView.center = sourceAttributes.initialPosition
                containerView.setNeedsLayout()
                containerView.layoutIfNeeded()
                containerView.subviews.forEach {
                    $0.setNeedsLayout()
                    $0.layoutIfNeeded()
                }
                containerView.contentView.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
            }
            else {
                containerView.transform = CGAffineTransform(
                    translationX: 0,
                    y: self.interactionController.interationDistance(for: containerView)
                )
            }
        }
        
        animator.addCompletion { _ in
            self.contentViews.forEach { $0.didDisappear() }
            
            self.willMove(toParent: nil)
            self.view.removeFromSuperview()
            self.removeFromParent()
    
            self.didDismiss?()
            completion?()
        }
        
        animator.startAnimation()
        
    }

    // MARK: - Replace Content View
    
    /// Fades the current contentView into the new contentView, resizing as needed
    /// - Parameter index: The stack index of the contentView, with 0 being the backmost view
    ///
    /// Note that this is different than `push` and `pop`, as this simply replaces the content of a view rather than adding
    /// an additional view to the stack.
    public func replaceContentView(at stackIndex: Int = 0, with contentView: PopupStackContentView) {
        guard stackIndex >= 0, stackIndex < self.contentContainerViews.count else { return }
        self.shouldAnimateKeyboardOpen = false
        
        let containerView = self.contentContainerViews[stackIndex]
        let oldContentView = containerView.contentView
        
        let newContentSize = self.contentSize(for: contentView)
        
        contentView.popupViewController = self
        contentView.alpha = 0
        
        containerView.contentSize = newContentSize
        containerView.contentView = contentView
        
        containerView.setNeedsLayout()
        containerView.layoutIfNeeded()
        
        contentView.center = CGPoint(x: containerView.bounds.midX, y: newContentSize.height / 2)
        
        oldContentView.willDisappear()
        contentView.willAppear()
        
        // If this is the primary content view (topmost in the stack),
        // inform interactionController so it can handle gestures
        if stackIndex == self.contentContainerViews.count - 1 {
            self.interactionController.didChangePrimaryContentView(containerView)
        }
        
        UIView.animate(withDuration: 0.15, animations: {
            oldContentView.alpha = 0
            contentView.alpha = 1
        }, completion: { _ in
            oldContentView.removeFromSuperview()
            oldContentView.didDisappear()
            contentView.didAppear()
            self.shouldAnimateKeyboardOpen = true
        })
        
        self.reloadContentSize()
        
    }
    
    
    // MARK: - Push/Pop
    
    /// Push a new content view onto the stack
    public func push(_ view: PopupStackContentView) {
        guard !self.isPopping else { return }
        self.shouldAnimateKeyboardOpen = false
        
        view.willAppear()
        view.popupViewController = self
        
        let containerView = ContentContainerView(contentView: view)
        containerView.contentSize = self.contentSize(for: view)
        
        containerView.transform = CGAffineTransform(
            translationX: 0,
            y: containerView.contentSize.height + 50
        )
                
        self.view.addSubview(containerView)
        self.contentContainerViews.append(containerView)
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        
        self.interactionController.didChangePrimaryContentView(containerView)
        
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.86,
            initialSpringVelocity: 0,
            options: [.allowUserInteraction, .beginFromCurrentState],
            animations: {
                
                for (i, container) in self.contentContainerViews.enumerated() {
                    if container === containerView {
                        container.transform = .identity
                    }
                    else if i == self.contentContainerViews.count - 2 {
                        container.setDimmed(true)
                        container.transform = self.interactionController.stackTransform(
                            for: container, stackIndex: 1, progress: 0
                        )
                    }
                    else {
                        container.setDimmed(true)
                        container.transform = self.interactionController.stackTransform(
                            for: container, stackIndex: 2, progress: 0
                        )
                    }
                }
                
            }, completion: { _ in
                view.didAppear()
                self.shouldAnimateKeyboardOpen = true
            })
    
    }
    
    private var isPopping = false
    
    /// Pop the current content view
    /// If there is only one content view in the stack, this method does nothing.
    public func pop() {
        guard !self.isPopping else { return }
        guard self.contentContainerViews.count > 1 else { return }

        self.isPopping = true
        
        let currentView = self.contentContainerViews[self.contentViews.count - 1]
        let previousView = self.contentContainerViews[self.contentViews.count - 2]

        currentView.contentView.willDisappear()
        previousView.contentView.willAppear()
        
        self.contentContainerViews.removeLast()
        
        self.interactionController.didChangePrimaryContentView(previousView)
        
        UIView.animate(
            withDuration: 0.45,
            delay: 0,
            usingSpringWithDamping: 0.84,
            initialSpringVelocity: 2,
            options: [.allowUserInteraction, .beginFromCurrentState],
            animations: {
                
                currentView.transform = CGAffineTransform(
                    translationX: 0,
                    y: self.interactionController.interationDistance(for: currentView)
                )
                
                for (i, container) in self.contentContainerViews.enumerated() {
                    
                    container.transform = self.interactionController.stackTransform(
                        for: container,
                        stackIndex: self.contentContainerViews.count - 1 - i,
                        progress: 1)
                    
                    if i == self.contentContainerViews.count - 1 {
                        container.setDimmed(false)
                    }
                    
                }
                
        }, completion: { _ in
            currentView.removeFromSuperview()
            currentView.contentView.didDisappear()
            previousView.contentView.didAppear()
            self.isPopping = false
        })
    }
}

// MARK: - InteractionControllerDelegate

extension PopupStackViewController {
    
    func interactionControllerDidTapOutside(_ controller: PopupStackInteractionController) {
        if self.contentContainerViews.count > 1 {
            self.pop()
        } else {
            self.hide()
        }
    }
    
    func interactionControllerWillCommitDismissal(_ controller: PopupStackInteractionController) {
        if self.contentContainerViews.count == 1 {
            self.shouldBlockLayout = true
            self.contentViews.forEach { $0.willDisappear() }
            self.willDismiss?()
        }
        else {
            self.isPopping = true
            self.contentContainerViews.last?.contentView.willDisappear()
            self.contentContainerViews[self.contentContainerViews.count - 2].contentView.willAppear()
        }
    }
    
    func interactionControllerDidCommitDismissal(_ controller: PopupStackInteractionController) {
        if self.contentContainerViews.count == 1 {
            self.willMove(toParent: nil)
            self.view.removeFromSuperview()
            self.removeFromParent()
            
            self.didDismiss?()
        }
        else {
            let last = self.contentContainerViews.removeLast()
            last.contentView.didDisappear()
            last.removeFromSuperview()
            if let currentView = self.contentContainerViews.last {
                self.interactionController.didChangePrimaryContentView(currentView)
                currentView.contentView.didAppear()
            }
            self.isPopping = false
        }
    }
    
}

// MARK: - UIViewController extension

extension UIViewController {
    
    func presentPopupViewController(
        _ viewController: PopupStackViewController,
        customSourceView: UIView? = nil,
        animationDuration: TimeInterval = 0.4
    ) {
        viewController.view.frame = self.view.bounds
        viewController.willMove(toParent: self)
        self.view.addSubview(viewController.view)
        self.addChild(viewController)
        
        viewController.show(customSourceView: customSourceView, animationDuration: animationDuration)
    }
    
}

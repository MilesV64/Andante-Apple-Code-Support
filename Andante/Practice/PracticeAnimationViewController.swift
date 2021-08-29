//
//  PracticeAnimationViewController.swift
//  Andante
//
//  Created by Miles Vinson on 12/4/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class PracticeAnimationViewController: UIViewController, UIGestureRecognizerDelegate {
    
    public let contentView = TransformIgnoringSafeAreaInsetsView()
    
    class var CornerRadius: CGFloat {
        return UIDevice.current.deviceCornerRadius()
    }
    
    class var PresentingScale: CGFloat {
        return 0.9
    }
    
    public var safeAreaInsets: UIEdgeInsets {
        return UIApplication.shared.windows.first?.safeAreaInsets ?? .zero
    }
    
    private let dismissAnimation = DismissAnimation()
    private let presentAnimation = PresentationAnimation()
    
    private let dimView = UIView()
        
    public var isCollapsed = false
    
    public var isShowingConfirmScreen = false
    
    public var isAnimating = false
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let gesture = UIPanGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presentAnimation.dimView = dimView
        dismissAnimation.dimView = dimView
        
        gesture.addTarget(self, action: #selector(handleGesture))
        self.gesture.delegate = self
        view.addGestureRecognizer(gesture)
        
        dimView.backgroundColor = Colors.dynamicColor(
            light: UIColor.black.withAlphaComponent(0.15),
            dark: Colors.text.withAlphaComponent(0.05))
        dimView.alpha = 0
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (presentingViewController as? AndanteViewController)?.contentView.addSubview(dimView)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return false
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.gesture {
            return !isShowingConfirmScreen
        }
        
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            
            let velocity = panGesture.velocity(in: self.view)
            
            if isShowingConfirmScreen {
                if velocity.x > 0 {
                    return abs(velocity.x) > abs(velocity.y)
                }
            }
            else {
                if velocity.x < 0 {
                    return abs(velocity.x) > abs(velocity.y)
                }
            }
            
        }
        
        return false
    }
    
    private var dragY: CGFloat = 0
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dimView.removeFromSuperview()
    }
    
    @objc func handleGesture() {
                
        if gesture.state == .began {
            dragY = view.frame.minY
        }
        else if gesture.state == .changed {
            gestureDidChange()
        }
        else if gesture.state == .ended {
            gestureDidEnd()
        }
    }
    
    public var statusBarStyle: UIStatusBarStyle = .lightContent {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }
    
    private func gestureDidChange() {
        guard let presentingVC = self.presentingViewController as? AndanteViewController else { return }
        
        let translation = max(0, dragY + gesture.translation(in: view).y)
        let percent = translation/view.bounds.height
        
        dimView.alpha = 1 - percent
        
        contentView.frame.origin.y = translation
        
        let scale = PracticeAnimationViewController.PresentingScale + (1-PracticeAnimationViewController.PresentingScale)*percent
        
        presentingVC.contentView.transform = CGAffineTransform(
            scaleX: scale, y: scale)
        presentingVC.contentView.layer.cornerRadius = 10 + (PracticeAnimationViewController.CornerRadius-10)*percent
        
        
        let insets = view.safeAreaInsets
        
        let presentingY = ((1-scale)*view.bounds.height)/2
        let breakpt = insets.top/2
        if presentingY < breakpt && statusBarStyle == .lightContent {
            UIView.animate(withDuration: 0.2) {
                self.statusBarStyle = .default
            }
        } else if presentingY >= breakpt && statusBarStyle == .default {
            UIView.animate(withDuration: 0.2) {
                self.statusBarStyle = .lightContent
            }
        }
        
        if translation > 0 {
            if PracticeAnimationViewController.CornerRadius == 0 {
                contentView.layer.cornerRadius = min(10*percent,1)*10
            } else {
                contentView.layer.cornerRadius = PracticeAnimationViewController.CornerRadius - (PracticeAnimationViewController.CornerRadius - 10)*min(1,percent*2)
            }
        } else {
            contentView.layer.cornerRadius = 0
        }
        
    }
    
    private func gestureDidEnd() {

        let translation = max(0, dragY + gesture.translation(in: view).y)
        let percent = translation/view.bounds.height
        
        let originalVelocity = gesture.velocity(in: self.view).y
        var velocity: CGFloat = 0
        if originalVelocity > 0 {
            velocity = originalVelocity / ((1-percent)*self.view.bounds.height)
        }
        else if originalVelocity < 0 {
            velocity = originalVelocity / ((percent)*self.view.bounds.height)
        }
        
        if velocity > 2 {
            UIView.animate(
                withDuration: 0.4, delay: 0,
                usingSpringWithDamping: 1,
                initialSpringVelocity: velocity*2,
                options: .curveLinear,
                animations: {
                
                    self.close()
                
                }, completion: {_ in
                    
                    self.collapse()
            })
            showTabBar()
            setClosedCornerRadius()
            
        }
        else if velocity < -2 {
            UIView.animate(
                withDuration: 0.4, delay: 0,
                usingSpringWithDamping: 1,
                initialSpringVelocity: -velocity,
                options: .curveLinear,
                animations: {
                
                    self.open()
                
                }, completion: nil)
            
            setOpenCornerRadius()
            
        }
        else {
            if percent > 0.5 {
                UIView.animateWithCurve(duration: 0.45, x1: 0.2, y1: 1, x2: 0.36, y2: 1, animation: {
                    self.close()
                }, completion: {
                    self.collapse()
                })
                showTabBar()
                setClosedCornerRadius()
            }
            else {
                
                UIView.animateWithCurve(duration: 0.45, x1: 0.2, y1: 1, x2: 0.36, y2: 1, animation: {
                    self.open()
                }, completion: nil)
                
                setOpenCornerRadius()
                
            }
        }
        
        
    }
    
    private func open() {
        guard let presentingVC = self.presentingViewController as? AndanteViewController else { return }

        contentView.frame.origin.y = 0
        presentingVC.contentView.transform = CGAffineTransform(
            scaleX: PracticeAnimationViewController.PresentingScale,
            y: PracticeAnimationViewController.PresentingScale)
        self.dimView.alpha = 1
        
        self.statusBarStyle = .lightContent
        self.setNeedsStatusBarAppearanceUpdate()
        
    }
    
    private func setOpenCornerRadius() {
        guard let presentingVC = self.presentingViewController as? AndanteViewController else { return }
        
        contentView.animateCornerRadius(
            duration: 0.2,
            from: contentView.layer.cornerRadius,
            to: PracticeAnimationViewController.CornerRadius)
        
        presentingVC.contentView.animateCornerRadius(
            duration: 0.2,
            from: presentingVC.contentView.layer.cornerRadius,
            to: 10)
        
    }
    
    //has to be sepparate from close bc of spring animation
    private func showTabBar() {
        
        guard
            let presentingVC = presentingViewController as? AndanteViewController,
            let tabbar = presentingVC.tabbar
        else { return }
        
        UIView.animateWithCurve(duration: 0.45, x1: 0.2, y1: 1, x2: 0.36, y2: 1, animation: {
            self.view.addSubview(tabbar)
            tabbar.layer.shadowOpacity = 0
            
            UIView.performWithoutAnimation {
                tabbar.frame.origin.y = self.view.bounds.maxY
            }
            
            tabbar.frame = CGRect(x: 0, y: self.view.bounds.maxY - 49 - self.safeAreaInsets.bottom, width: tabbar.bounds.width, height: 49 + self.safeAreaInsets.bottom)
        }, completion: {
            
        })
    }
    
    private func close() {
        guard let presentingVC = self.presentingViewController as? AndanteViewController else { return }
                
        isAnimating = true

        presentingVC.contentView.transform = .identity
        self.dimView.alpha = 0
        
        self.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
        
        var collapsedSessionView: CollapsedSessionView!
        UIView.performWithoutAnimation {
            collapsedSessionView = CollapsedSessionView(self as! PracticeViewController)
            
            if presentingVC.isSidebarEnabled == false {
                collapsedSessionView.frame = CGRect(
                    x: 0, y: contentView.frame.minY+4, width: contentView.bounds.width, height: contentView.bounds.height)
            }
            
            presentingVC.showCollapsedSessionView(collapsedSessionView)
        }
        
        collapsedSessionView.animate(transform: presentingVC.isSidebarEnabled == false)

        if !presentingVC.isSidebarEnabled {
            (self as? PracticeViewController)?.contentView.alpha = 0
            contentView.frame.origin.y = view.bounds.maxY - 49 - safeAreaInsets.bottom - 54
            collapsedSessionView.frame.origin.y = contentView.frame.origin.y
        } else {
            contentView.frame.origin.y = view.bounds.maxY
        }

    }
    
    private func setClosedCornerRadius() {
        guard let presentingVC = self.presentingViewController as? AndanteViewController else { return }
        
        contentView.animateCornerRadius(
            duration: 0.1,
            from: contentView.layer.cornerRadius,
            to: 0)
        
        presentingVC.contentView.animateCornerRadius(
            duration: 0.2,
            from: presentingVC.contentView.layer.cornerRadius,
            to: PracticeAnimationViewController.CornerRadius)
    }
    
    private func collapse() {
        didCollapse()
        
        if let presentingVC = self.presentingViewController as? AndanteViewController, let tabbar = presentingVC.tabbar {
            presentingVC.contentView.layer.cornerRadius = 0
            
            tabbar.layer.shadowOpacity = 0.16
            if let collapsedSessionView = presentingVC.collapsedSessionView {
                collapsedSessionView.bounds.size.height = 54
                presentingVC.contentView.insertSubview(tabbar, belowSubview: collapsedSessionView)
                presentingVC.view.setNeedsLayout()
            }
            
        }
        self.dismiss(animated: false, completion: nil)
        
        isAnimating = false
        isCollapsed = true
    }
    
    public func didCollapse() {
        
    }
    
    public func animateDismiss() {
        guard let presentingVC = self.presentingViewController as? AndanteViewController else { return }
        
        UIView.animateWithCurve(duration: 0.6, x1: 0.2, y1: 1, x2: 0.36, y2: 1, animation: {
            presentingVC.contentView.transform = .identity
            self.view.alpha = 0
            self.dimView.alpha = 0
        }, completion: {
            presentingVC.contentView.layer.cornerRadius = 0
        })
        
        presentingVC.contentView.animateCornerRadius(
            duration: 0.4,
            from: presentingVC.contentView.layer.cornerRadius,
            to: PracticeAnimationViewController.CornerRadius)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        dimView.frame = view.bounds
    }
    
    private func adjustInsets(_ from: UIEdgeInsets, to: UIEdgeInsets, percent: CGFloat) -> UIEdgeInsets {
        var insets = UIEdgeInsets()
        insets.left = from.left + (to.left - from.left)*percent
        insets.top = from.top + (to.top - from.top)*percent
        insets.right = from.right + (to.right - from.right)*percent
        insets.bottom = from.bottom + (to.bottom - from.bottom)*percent
        return insets
    }
    
}

extension PracticeAnimationViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dismissAnimation
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return presentAnimation
    }
    
}

fileprivate class PresentationAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    
    public var dimView: UIView?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.6
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let presentingVC = transitionContext.viewController(forKey: .from) as? AndanteViewController,
            let vc = transitionContext.viewController(forKey: .to) as? PracticeViewController
        else { return }
        
        let view = vc.contentView
        vc.contentView.alpha = 1
        
        let presentingView = presentingVC.contentView
        
        
        var tabbarView: Tabbar?
        var collapsedView: CollapsedSessionView?
        if vc.isCollapsed {
            if let collapsedSessionView = presentingVC.collapsedSessionView {
                collapsedView = collapsedSessionView
                
                view.frame = presentingView.bounds.offsetBy(dx: 0, dy: collapsedSessionView.frame.minY)
                
                if presentingVC.isSidebarEnabled == false {
                    vc.practiceView.alpha = 0
                }
                                
                view.insertSubview(collapsedSessionView, at: 0)
                collapsedSessionView.frame.origin.y = 0
                
                UIView.animateWithCurve(
                    duration: 0.4,
                    curve: UIView.CustomAnimationCurve.exponential.easeOut
                ) {
                    vc.practiceView.alpha = 1
                    collapsedView?.alpha = 0
                } completion: { }
                
                if let tabbar = presentingVC.tabbar {
                    view.addSubview(tabbar)
                    tabbar.frame.origin.y = view.bounds.height - view.frame.minY - 49 - vc.safeAreaInsets.bottom
                    tabbarView = tabbar
                    
                }
            }
        }
        else {
            view.frame = presentingView.bounds.offsetBy(dx: 0, dy: presentingView.bounds.height)
        }
        
        transitionContext.containerView.addSubview(vc.view)
        vc.view.frame = presentingView.bounds
        
        let cornerRadius = UIDevice.current.deviceCornerRadius()
                
        UIView.animateWithCurve(
            duration: transitionDuration(using: transitionContext),
            curve: UIView.CustomAnimationCurve.exponential.easeOut
        ) {
            view.frame = presentingView.bounds
            presentingView.transform = CGAffineTransform(
                scaleX: PracticeAnimationViewController.PresentingScale,
                y: PracticeAnimationViewController.PresentingScale)
            self.dimView?.alpha = 1
            tabbarView?.frame.origin.y = view.bounds.maxY
            collapsedView?.frame = view.bounds
            vc.statusBarStyle = .lightContent
            vc.setNeedsStatusBarAppearanceUpdate()
            
        } completion: {
            transitionContext.completeTransition(true)
            view.layer.cornerRadius = 0
            if let tabbar = tabbarView {
                presentingVC.contentView.addSubview(tabbar)
            }
            collapsedView?.removeFromSuperview()
            collapsedView?.practiceViewController = nil
            presentingVC.collapsedSessionView = nil
            vc.isCollapsed = false
        }
        
        presentingView.layer.cornerCurve = .continuous
        view.layer.cornerCurve = .continuous
        view.layer.masksToBounds = true
        presentingView.layer.masksToBounds = true

        presentingView.animateCornerRadius(
            duration: transitionDuration(using: transitionContext)/2,
            from: cornerRadius, to: 10)
        
        view.animateCornerRadius(
            duration: transitionDuration(using: transitionContext)/2,
            from: 0, to: cornerRadius)
        
    }
    
}

fileprivate class DismissAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    
    public var dimView: UIView?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.6
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let presentingVC = transitionContext.viewController(forKey: .to) as? AndanteViewController,
            let vc = transitionContext.viewController(forKey: .from) as? PracticeAnimationViewController
        else { return }
        
        let view = vc.contentView
        
        let presentingView = presentingVC.contentView
        
        let cornerRadius = PracticeAnimationViewController.CornerRadius
                
        UIView.animateWithCurve(
            duration: transitionDuration(using: transitionContext),
            curve: UIView.CustomAnimationCurve.exponential.easeOut
        ) {
            view.frame = presentingView.bounds.offsetBy(dx: 0, dy: presentingView.bounds.height)
            presentingView.transform = .identity
            self.dimView?.alpha = 0
            
        } completion: {
            transitionContext.completeTransition(true)
            vc.view.removeFromSuperview()
            presentingView.layer.cornerRadius = 0
        }
        
        presentingView.animateCornerRadius(
            duration: transitionDuration(using: transitionContext)/2,
            from: 10, to: cornerRadius)
        
        view.animateCornerRadius(
            duration: transitionDuration(using: transitionContext)/2,
            from: cornerRadius, to: 0)
        
    }
    
}

fileprivate extension UIView {
    func animateCornerRadius(duration: TimeInterval, from: CGFloat, to: CGFloat) {
        let anim = CABasicAnimation(keyPath: "cornerRadius")
        anim.fromValue = from
        anim.toValue = to
        anim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        anim.duration = duration
        self.layer.add(anim, forKey: "cornerRadius")
        self.layer.cornerRadius = to
    }
}

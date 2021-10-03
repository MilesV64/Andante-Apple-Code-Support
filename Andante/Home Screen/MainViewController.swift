//
//  NavigationController.swift
//  Andante
//
//  Created by Miles Vinson on 10/29/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import UIKit
import MessageUI
import StoreKit

public class ParentSafeAreaInsetsView: UIView {
    private weak var vc: UIViewController?
    
    init(vc: UIViewController) {
        self.vc = vc
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public var safeAreaInsets: UIEdgeInsets {
        if let vc = vc, let parent = vc.parent {
            return parent.view.safeAreaInsets
        } else {
            return super.safeAreaInsets
        }
    }
}

class MainViewController: UIViewController, UIGestureRecognizerDelegate, AnimatorDelegate {
    
    func pageReselected() {}
    func didAddSession(session: CDSession) {}
    func didDeleteSession(session: CDSession) {}
    func dayDidChange() {}
    
    var containerViewController: AndanteViewController!
    var containerView = UIView()
    var contentView = UIView()
    var scrollView: UIScrollView? {
        didSet {
            self.scrollViewDidLoad()
        }
    }
    
    private var pullToSettingsView = PullToSettingsView()
                
    private var headerView: HeaderView!
    
    public var mainHeaderView: HeaderView {
        return headerView
    }
    
    public var isBotViewFocused = false
    
    private var navAccessoryView = Separator(position: .bottom)
    private var showNavAccessoryView = false
    
    public var additionalTopInset: CGFloat = 0
    
    private var didLoad = false
    
    override func loadView() {
        self.view = ParentSafeAreaInsetsView(vc: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = Colors.backgroundColor
        
        self.view.clipsToBounds = false
        self.view.addSubview(containerView)
        
        contentView.clipsToBounds = false
        containerView.addSubview(contentView)
        
        containerView.addSubview(navAccessoryView)
        navAccessoryView.bounds.size.height = 44
        navAccessoryView.backgroundColor = Colors.foregroundColor
        navAccessoryView.setBarShadow()
        headerView = HeaderView()
        
        headerView.profileButtonHandler = {
            let settingsVC = SettingsContainerViewController()
            self.containerViewController.presentModal(settingsVC, animated: true, completion: nil)
        }
        
        headerView.streakViewHandler = {
            //self.tabBarController?.presentAlert(StreakDetailViewController())
        }
        
        headerView.profile = User.getActiveProfile()
        
        containerView.addSubview(headerView)
         
        didLoad = true
    }
    
    func scrollViewDidLoad() {
        self.scrollView?.addSubview(self.pullToSettingsView)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        navAccessoryView.setBarShadow()
    }

    private var firstLoad = true
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        print("viewDidLayoutSubviews")
        
        containerView.contextualFrame = self.view.bounds
        
        contentView.contextualFrame = containerView.bounds
        
        headerView.isSidebarLayout = containerViewController.isSidebarEnabled
        updateHeaderView()

        if containerViewController.isSidebarEnabled {
            scrollView?.verticalScrollIndicatorInsets.bottom = 0
        } else {
            scrollView?.verticalScrollIndicatorInsets.bottom = -view.safeAreaInsets.bottom
        }

        if firstLoad {
            let topInset: CGFloat = headerView.height + self.view.safeAreaInsets.top + additionalTopInset
            scrollView?.setContentOffset(CGPoint(x: 0, y: -topInset), animated: false)
            firstLoad = false
        }
        
    }
    
    private func layoutPullToSettingsView() {
        if let scrollView = self.scrollView {
            let maxY = -self.additionalTopInset
            let minY = min(0, scrollView.contentOffset.y + scrollView.contentInset.top - self.additionalTopInset)
            let height = maxY - minY
            
            let frame = CGRect(
                x: -scrollView.contentInset.left, y: minY, width: scrollView.bounds.width, height: maxY - minY)
            
            if frame != self.pullToSettingsView.frame {
                self.pullToSettingsView.frame = frame
                self.pullToSettingsView.setProgress(max(0, min(1, height / 100)))
            }
            
        }
        
        if self.headerView.profileView.superview != self.view {
            if self.pullToSettingsView.progress >= 1 {
                let convertedFrame = self.headerView.topView.convert(self.headerView.profileView.frame, to: self.view)
                self.view.addSubview(self.headerView.profileView)
                self.headerView.profileView.frame = convertedFrame

                UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState]) {

                    let center = CGPoint(
                        x: self.pullToSettingsView.bounds.midX,
                        y: self.pullToSettingsView.bounds.maxY - 40 - self.pullToSettingsView.bounds.height * 0.1)
                    self.headerView.profileView.center = self.pullToSettingsView.convert(center, to: self.view)

                } completion: { _ in
                    //
                }
            }
        }
        else {
            if self.pullToSettingsView.progress < 1 {
                self.headerView.profileView.frame = self.view.convert(self.headerView.profileView.frame, to: self.headerView.topView)
                self.headerView.topView.addSubview(self.headerView.profileView)
                
                UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState]) {
                    self.headerView.profileView.frame = self.headerView.profileFrame
                } completion: { _ in
                    //
                }
            }
            else {
                let center = CGPoint(
                    x: self.pullToSettingsView.bounds.midX,
                    y: self.pullToSettingsView.bounds.maxY - 40 - self.pullToSettingsView.bounds.height * 0.1)
                self.headerView.profileView.center = self.pullToSettingsView.convert(center, to: self.view)
            }
        }
        
    }
    
    private func updateHeaderView() {
        if let scrollView = scrollView {
            
            if isBotViewFocused && !containerViewController.isSidebarEnabled {
                let height = (headerView.height - headerView.minHeight) + self.view.safeAreaInsets.top
                
                let extraInset = additionalTopInset + (showNavAccessoryView ? navAccessoryView.bounds.height : 0)
                scrollView.contentInset.top = height + extraInset
                scrollView.verticalScrollIndicatorInsets.top = height - self.view.safeAreaInsets.top + extraInset - additionalTopInset
                
                headerView.bounds.size = CGSize(
                    width: self.view.bounds.width,
                    height: height)
                headerView.frame.origin = .zero
            }
            else {
                let height = headerView.height + self.view.safeAreaInsets.top
                
                let extraInset = additionalTopInset + (showNavAccessoryView ? navAccessoryView.bounds.height : 0)
                scrollView.contentInset.top = height + extraInset
                scrollView.verticalScrollIndicatorInsets.top = height - self.view.safeAreaInsets.top + extraInset - additionalTopInset
                            
                let barHeight = clamp(value: height - (height + (scrollView.contentOffset.y + extraInset)),
                                      min: headerView.minHeight + self.view.safeAreaInsets.top,
                                      max: height)
                
                headerView.bounds.size = CGSize(
                    width: self.view.bounds.width,
                    height: barHeight)
                headerView.frame.origin = .zero
            }
            
            
            if showNavAccessoryView {
                navAccessoryView.frame = CGRect(x: 0, y: headerView.frame.maxY, width: self.view.bounds.width, height: navAccessoryView.bounds.height)
            }
            else {
                navAccessoryView.frame = CGRect(x: 0, y: headerView.frame.maxY - navAccessoryView.bounds.height, width: self.view.bounds.width, height: navAccessoryView.bounds.height)
            }

        }
    }
    
    func didScroll(scrollView: UIScrollView) {
        updateHeaderView()
        self.layoutPullToSettingsView()
    }
    
    func willEndScroll(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        if self.pullToSettingsView.progress >= 1 {
            self.pullToSettingsView.didPullToOpenSettings()
            let settingsVC = SettingsContainerViewController()
            self.containerViewController.presentModal(settingsVC, animated: true, completion: nil)
        }
        
        if containerViewController.isSidebarEnabled || isBotViewFocused {
            return
        }
        
        let accessoryHeight: CGFloat = additionalTopInset + (showNavAccessoryView ? navAccessoryView.bounds.height : 0)
        let minHeight = headerView.minHeight + accessoryHeight
        let maxHeight = headerView.height + accessoryHeight
        
        let height = headerView.height + self.view.safeAreaInsets.top + accessoryHeight
        let offset = height - (height + targetContentOffset.pointee.y) - self.view.safeAreaInsets.top
        
        if offset > minHeight && offset < maxHeight {
            if (offset - minHeight) < (maxHeight - offset) {
                targetContentOffset.initialize(to: CGPoint(
                    x: 0, y: -(minHeight + self.view.safeAreaInsets.top)))
            }
            else {
                targetContentOffset.initialize(to: CGPoint(
                    x: 0, y: -(maxHeight + self.view.safeAreaInsets.top)))
            }
        }
                
    }
    
    override var title: String? {
        didSet {
            if didLoad {
                headerView.title = title
            }
        }
    }
    
    func setTopView(_ view: UIView) {
        headerView.botView.addSubview(view)
    }
    
    public func setNavAccessoryView(_ view: UIView) {
        if showNavAccessoryView {
            navAccessoryView.subviews.forEach { $0.removeFromSuperview() }
            navAccessoryView.addSubview(view)
            navAccessoryView.bounds.size.height = view.bounds.size.height
            view.frame = navAccessoryView.bounds
            UIView.animateWithCurve(duration: 0.25, curve: UIView.CustomAnimationCurve.cubic.easeOut, animation: {
                if let scrollView = self.scrollView {
                    scrollView.setContentOffset(CGPoint(x: 0, y: -(self.headerView.height + self.view.safeAreaInsets.top + self.navAccessoryView.bounds.height)), animated: false)
                }
            }, completion: nil)
            
            UIView.animate(withDuration: 0.2) {
                view.alpha = 1
            }
            return
        }
        
        view.alpha = 0
        navAccessoryView.addSubview(view)
        navAccessoryView.bounds.size.height = view.bounds.size.height
        view.frame = navAccessoryView.bounds
        navAccessoryView.frame.origin = CGPoint(x: 0, y: headerView.frame.maxY - view.bounds.size.height)
        showNavAccessoryView = true
        
        UIView.animateWithCurve(duration: 0.25, curve: UIView.CustomAnimationCurve.cubic.easeOut, animation: {
            if let scrollView = self.scrollView {
                scrollView.setContentOffset(CGPoint(x: 0, y: -(self.headerView.height + self.view.safeAreaInsets.top + self.navAccessoryView.bounds.height + self.additionalTopInset)), animated: false)
            }
        }, completion: nil)
        
        UIView.animate(withDuration: 0.2) {
            view.alpha = 1
        }
        
    }
    
    public func removeNavAccessoryView() {
        showNavAccessoryView = false
        
        UIView.animateWithCurve(duration: 0.3, curve: UIView.CustomAnimationCurve.exponential.easeOut, animation: {
            self.viewDidLayoutSubviews()
        }) {
            for subview in self.navAccessoryView.subviews {
                subview.removeFromSuperview()
            }
        }
        
        UIView.animate(withDuration: 0.05) {
            for subview in self.navAccessoryView.subviews {
                subview.alpha = 0
            }
        }

    }
    
    public func didChangeProfile(profile: CDProfile) {
        if self.didLoad {
            self.headerView.profile = profile
        }
    }
    
    public var headerFrame: CGRect {
        return headerView.frame
    }
    
    
    private let animator = Animator()
    func scrollToTop(scrollView: UIScrollView) {
        animator.delegate = self
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
        
        animator.startValue = scrollView.contentOffset.y
        
        let extraInset: CGFloat = self.additionalTopInset + (self.showNavAccessoryView ? self.navAccessoryView.bounds.height : 0)
        let totalInset: CGFloat = self.headerView.height + extraInset
        
        animator.endValue = -(totalInset + self.view.safeAreaInsets.top)

        animator.startAnimation(duration: 0.6, easing: Curve.exponential.easeOut)
        
    }
    
    func scrollViewWillDrag() {
        animator.stopAnimation()
    }
    
    func animationDidUpdate(phase: CGFloat) {
        guard let scrollView = self.scrollView else { return }
        let start = animator.startValue as! CGFloat
        let end = animator.endValue as! CGFloat
        
        let value = start + (end - start)*phase
        scrollView.setContentOffset(
            CGPoint(x: scrollView.contentOffset.x, y: value), animated: false)
        
        
    }
    
    public func setBotViewFocused(_ focused: Bool) {
        self.isBotViewFocused = focused
        
        var shouldScrollToTop = false
        if !focused, !containerViewController.isSidebarEnabled, let scrollView = self.scrollView {
            if scrollView.contentOffset.y + scrollView.contentInset.top == 0 {
                shouldScrollToTop = true
            }
        }
                
        UIView.animateWithCurve(duration: 0.3, curve: UIView.CustomAnimationCurve.cubic.easeOut) {
            self.updateHeaderView()
            if shouldScrollToTop, let scrollView = self.scrollView {
                scrollView.setContentOffset(
                    CGPoint(x: scrollView.contentOffset.x, y: -scrollView.contentInset.top),
                    animated: false)
            }
        } completion: { }
        
        self.headerView.setFocused(focused, isScrolledToTop: shouldScrollToTop)
        
    }
    
}


class NavBackButton: UIView {
    
    public var altImage: UIImage? {
        didSet {
            button.setImage(altImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        }
    }
    
    private let button = UIButton(type: .system)
    
    public var handler: (()->Void)?
    
    init() {
        super.init(frame: .zero)
        
        //button.setImage(UIImage(named: "BackButton")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = Colors.text
        
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        self.addSubview(button)
        
        self.widthAnchor.constraint(equalToConstant: 60).isActive = true
        self.heightAnchor.constraint(equalToConstant: 40).isActive = true
        self.transform = CGAffineTransform(translationX: -6, y: 0)
    }
    
    @objc func didTapButton() {
        handler?()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        button.frame = self.bounds
        button.roundCorners()
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        button.layer.borderColor = Colors.separatorColor.cgColor
        
    }
}

class NavButton: UIView {
    
    public let button = UIButton(type: .system)
    
    public var handler: (()->Void)?
    
    init(title: String?, color: UIColor?, font: UIFont) {
        super.init(frame: .zero)
        
        button.setTitle(title, for: .normal)
        button.setTitleColor(color, for: .normal)
        button.titleLabel?.font = font
        
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        self.addSubview(button)
        
        self.widthAnchor.constraint(equalToConstant: 80).isActive = true
        self.heightAnchor.constraint(equalToConstant: 40).isActive = true
        self.transform = CGAffineTransform(translationX: 16, y: 0)
    }
    
    @objc func didTapButton() {
        handler?()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        button.frame = self.bounds
    }
    
}

class ProfileImagePushButton: PushButton {
    class var bgColor: UIColor {
        return Colors.dynamicColor(light: Colors.lightColor, dark: Colors.lightColor)
    }
    
    public var profileImg: ProfileImageView!
    
    override init() {
        super.init()
        profileImg = ProfileImageView(profile: User.getActiveProfile())
        profileImg.backgroundColor = ProfileImagePushButton.bgColor
        self.transformScale = 0.85
        profileImg.inset = 8
        self.addSubview(profileImg)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        profileImg.frame = self.bounds
        self.cornerRadius = self.bounds.height/2
    }
}

extension UIViewController {
    func NavigationController() -> UINavigationController {
        return UINavigationController(rootViewController: self)
    }
}

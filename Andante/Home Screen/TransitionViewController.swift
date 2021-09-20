//
//  TransitionViewController.swift
//  Andante
//
//  Created by Miles Vinson on 7/23/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class TransitionContentView: UIView {
    
    let contentView = UIView()
    let shadowView = UIView()
    
    public var useRoundCorners = true {
        didSet {
            if useRoundCorners {
                contentView.roundCorners(UIDevice.current.deviceCornerRadius())
            } else {
                contentView.roundCorners(0)
            }
        }
    }
     
    init() {
        super.init(frame: .zero)
        
        shadowView.backgroundColor = .clear
        shadowView.setShadow(radius: 8, yOffset: 0, opacity: 0.1, color: Colors.barShadowColor)
        shadowView.layer.shouldRasterize = true
        shadowView.layer.rasterizationScale = UIScreen.main.scale
        super.addSubview(shadowView)
        
        contentView.clipsToBounds = true
        contentView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
        contentView.backgroundColor = Colors.foregroundColor
        super.addSubview(contentView)
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        shadowView.setShadow(radius: 8, yOffset: 0, opacity: 0.1, color: Colors.barShadowColor)

    }
    
    override var backgroundColor: UIColor? {
        get {
            return contentView.backgroundColor
        }
        set {
            contentView.backgroundColor = newValue
        }
    }
    
    public func addNonContentSubview(_ view: UIView) {
        super.insertSubview(view, at: 0)
    }
    
    override func addSubview(_ view: UIView) {
        contentView.addSubview(view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: useRoundCorners ? UIDevice.current.deviceCornerRadius() : 10)
        shadowView.layer.shadowPath = shadowPath.cgPath
        
        shadowView.frame = self.bounds
        contentView.frame = self.bounds
        
    }
}

class TransitionViewController: UIViewController {
    
    private let dimView = UIView()
    public let panGesture = UIPanGestureRecognizer()
    
    //to coverup black space that appears to the right on bouncing of animation
    private let extraView = UIView()
    
    public var shouldAnimatePresentation = true
    
    public weak var presentingView: UIView? {
        return presentingViewController?.view
    }
    
    public var identityTransform: CGFloat {
        return 0
    }

    enum TransitionStyle {
        case push, overlap
    }
    
    private var contentView: TransitionContentView {
        return self.view as! TransitionContentView
    }
    
    public var transitionStyle: TransitionStyle = .overlap {
        didSet {
            switch self.transitionStyle {
            case .overlap:
                self.contentView.shadowView.isHidden = false
                self.dimView.isHidden = false
                self.contentView.useRoundCorners = true
                
            case .push:
                self.contentView.shadowView.isHidden = true
                self.dimView.isHidden = true
                self.contentView.useRoundCorners = false
            }
        }
    }
    
    /// The total transform to be applied to the parent, as a positive value
    private var parentTransform: CGFloat {
        switch self.transitionStyle {
        case .overlap: return 60
        case .push: return self.view.bounds.width
        }
    }
    
    convenience init(shouldAnimatePresentation: Bool) {
        self.init()
        self.shouldAnimatePresentation = shouldAnimatePresentation
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.modalPresentationStyle = .overFullScreen
        self.contentView.useRoundCorners = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = TransitionContentView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.view.isHidden = false
        
        if let presentingView = self.presentingView, shouldAnimatePresentation {
            self.view.transform = CGAffineTransform(translationX: presentingView.bounds.width, y: 0)
            self.inputAccessoryView?.transform = self.view.transform

            UIView.animateWithCurve(duration: 0.55, x1: 0.2, y1: 1, x2: 0.36, y2: 1, animation: {
                self.view.isUserInteractionEnabled = false
                self.inputAccessoryView?.transform = .identity
                self.dimView.alpha = 1
                presentingView.transform = CGAffineTransform(translationX: -self.parentTransform, y: 0)
                self.view.transform = CGAffineTransform(translationX: self.identityTransform, y: 0)
            }, completion: {
                presentingView.transform = .identity
                self.view.transform = .identity
                self.view.isUserInteractionEnabled = true
                self.parent?.view.isUserInteractionEnabled = true
            })
            
            self.didAppear()
        }
        else {
            self.didAppear()
        }
        
    }
    
    public func didAppear() {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.isHidden = shouldAnimatePresentation
        self.inputAccessoryView?.isHidden = true
        
        dimView.alpha = shouldAnimatePresentation ? 0 : 1
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        dimView.isUserInteractionEnabled = true
        (self.view as! TransitionContentView).addNonContentSubview(dimView)
        NSLayoutConstraint.activate([
            dimView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            dimView.topAnchor.constraint(equalTo: self.view.topAnchor),
            dimView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            dimView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 2)
        ])
        
        self.view.addGestureRecognizer(panGesture)
        panGesture.addTarget(self, action: #selector(handlePanGesture(_:)))
        
        extraView.backgroundColor = Colors.foregroundColor
        (self.view as! TransitionContentView).addSubview(extraView)
        
    }
    

    public func viewDidBeginDragging() {
        
    }
    
    public func willAppear() {
        
    }
    
    @objc func handlePanGesture(_ sender: UIScreenEdgePanGestureRecognizer) {
        let translation = max(0, sender.translation(in: self.view).x)
        let progress = translation/self.view.bounds.width
        
        if sender.state == .began || sender.state == .changed {
            if sender.state == .began {
                viewDidBeginDragging()
            }
            self.view.transform = CGAffineTransform(
                translationX: translation + self.identityTransform*(1-progress), y: 0)
            self.inputAccessoryView?.transform = CGAffineTransform(translationX: translation, y: 0)
            presentingView?.transform = CGAffineTransform(translationX: -self.parentTransform*(1-progress), y: 0)
            self.dimView.alpha = 1 - progress
        }
        else {
            let originalVelocity = sender.velocity(in: self.view).x
            var velocity: CGFloat = 0
            if originalVelocity > 0 {
                velocity = originalVelocity / ((1-progress)*self.view.bounds.width)
            }
            else if originalVelocity < 0 {
                velocity = originalVelocity / ((progress)*self.view.bounds.width)
            }
            
            if velocity > 0.5 {
                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: velocity*2, options: .curveLinear, animations: {
                    self.view.transform = CGAffineTransform(translationX: self.view.bounds.width, y: 0)
                    self.inputAccessoryView?.transform = CGAffineTransform(translationX: self.view.bounds.width, y: 0)
                    self.presentingView?.transform = .identity
                    self.dimView.alpha = 0
                }, completion: { complete in
                    self.dismiss(animated: false)
                })
                
            }
            else if velocity < -2 {
                willAppear()
                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: -velocity, options: .curveLinear, animations: {
                    self.view.transform = CGAffineTransform(translationX: self.identityTransform, y: 0)
                    self.inputAccessoryView?.transform = CGAffineTransform(translationX: 0, y: 0)
                    self.presentingView?.transform = CGAffineTransform(translationX: -self.parentTransform, y: 0)
                    self.dimView.alpha = 1
                }, completion: { _ in
                    self.view.transform = .identity
                    self.presentingView?.transform = .identity
                })
            }
            else {
                if progress > 0.5 {
                    UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                        self.view.transform = CGAffineTransform(translationX: self.view.bounds.width, y: 0)
                        self.inputAccessoryView?.transform = CGAffineTransform(translationX: self.view.bounds.width, y: 0)
                        self.presentingView?.transform = .identity
                        self.dimView.alpha = 0
                    }, completion: { complete in
                        self.dismiss(animated: false)
                    })
                }
                else {
                    willAppear()
                    UIView.animateWithCurve(duration: 0.5, x1: 0.2, y1: 1, x2: 0.36, y2: 1, animation: {
                        self.view.transform = CGAffineTransform(translationX: self.identityTransform, y: 0)
                        self.inputAccessoryView?.transform = CGAffineTransform(translationX: 0, y: 0)
                        self.presentingView?.transform = CGAffineTransform(translationX: -self.parentTransform, y: 0)
                        self.dimView.alpha = 1
                    }, completion: {
                        self.view.transform = .identity
                        self.presentingView?.transform = .identity
                    })
                }
            }
            
        }
    }
    
    public func close(animated: Bool = true, completion: (()->Void)? = nil) {
        self.view.transform = CGAffineTransform(translationX: self.identityTransform, y: 0)
        self.presentingView?.transform = CGAffineTransform(translationX: -self.view.bounds.width, y: 0)
        if animated {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                self.view.transform = CGAffineTransform(translationX: self.view.bounds.width, y: 0)
                self.inputAccessoryView?.transform = CGAffineTransform(translationX: self.view.bounds.width, y: 0)
                self.presentingView?.transform = .identity
                self.dimView.alpha = 0
            }, completion: { complete in
                self.dismiss(animated: false, completion: completion)
            })
        }
        else {
            self.presentingView?.transform = .identity
            self.dismiss(animated: false, completion: completion)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        extraView.frame = self.view.bounds.offsetBy(dx: self.view.bounds.width, dy: 0)
        
    }
    
    
    
}

class ChildTransitionViewController: TransitionViewController, UIGestureRecognizerDelegate {
    
    override weak var presentingView: UIView? {
        return self.parent?.view
    }
    
    override var identityTransform: CGFloat {
        return self.view.bounds.width
    }
    
    private var firstAppear = true
    override func viewDidAppear(_ animated: Bool) {
        
        if !firstAppear {
            return
        }
                
        firstAppear = false
        
        super.viewDidAppear(animated)
        
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.transitionStyle = .push
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        panGesture.delegate = self
        (self.view as! TransitionContentView).useRoundCorners = false
        
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return false
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = panGesture.velocity(in: self.view)
            if velocity.x > 0 {
                return velocity.x > velocity.y
            }
        }
        return false
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
    
}

extension UIViewController {
    func addChildTransitionController(_ child: ChildTransitionViewController) {
        self.addChild(child)
        self.view.addSubview(child.view)
        self.view.isUserInteractionEnabled = false
        child.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            child.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            child.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            child.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        child.didMove(toParent: self)
    }
}

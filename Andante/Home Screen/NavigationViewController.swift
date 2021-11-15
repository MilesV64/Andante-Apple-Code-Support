
//
//  NavigationViewController.swift
//  Andante
//
//  Created by Miles on 11/13/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class NavigatableViewController: UIViewController {
    
    weak var navigationViewController: NavigationViewController?
    
    public func viewDidBeginDragging() {
        //
    }
    
}

class NavigationViewController: UIViewController, NavigationInteractionControllerDelegate {
    
    /// Place 'root' content here
    /// Relies on subclass to lay out and add to view hierarchy
    public let navigationContentView = UIView()
        
    /// The navigated view controller, if available
    public var navigatedViewController: NavigatableViewController? {
        return self.containerView?.viewController
    }
    
    public let dimView = UIView()
    
    private let interactionController = NavigationInteractionController()
    
    private(set) var containerView: ContainerView?
    
    class ContainerView: UIView {
        
        private let contentView = UIView()
        
        let viewController: NavigatableViewController
        
        init(viewController: NavigatableViewController, frame: CGRect) {
            self.viewController = viewController
            super.init(frame: frame)
            
            if UIDevice.current.userInterfaceIdiom == .phone {
                let cornerRadius = UIDevice.current.deviceCornerRadius()
                self.roundCorners(cornerRadius)
                self.contentView.clipsToBounds = true
                self.contentView.roundCorners(cornerRadius)
            }
//
//            self.layer.shadowOpacity = 0.06
//            self.layer.shadowRadius = 20
//            self.layer.shadowColor = UIColor.black.cgColor
//
            self.contentView.frame = frame
            self.contentView.addSubview(viewController.view)
            self.addSubview(self.contentView)
            
            self.contentView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                contentView.widthAnchor.constraint(equalTo: self.widthAnchor),
                contentView.heightAnchor.constraint(equalTo: self.heightAnchor),
                contentView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                contentView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
            ])
            
            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                viewController.view.widthAnchor.constraint(equalTo: contentView.widthAnchor),
                viewController.view.heightAnchor.constraint(equalTo: contentView.heightAnchor),
                viewController.view.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                viewController.view.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            ])
            
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            //self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.layer.cornerRadius).cgPath
           
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.interactionController.delegate = self
        
        self.navigationContentView.clipsToBounds = true
        self.view.addSubview(self.navigationContentView)
        
        self.dimView.translatesAutoresizingMaskIntoConstraints = false
        self.dimView.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        self.dimView.alpha = 0
                
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

    }
    
    public func push(_ viewController: NavigatableViewController, animated: Bool = true) {
        viewController.navigationViewController = self
        
        let containerView = ContainerView(viewController: viewController, frame: self.navigationContentView.bounds)
        
        viewController.willMove(toParent: self)
        self.view.addSubview(containerView)
        self.addChild(viewController)
        
        viewController.view.addGestureRecognizer(self.interactionController.panGestureRecognizer)
                
        self.navigationContentView.addSubview(self.dimView)
        
        self.setNavigationConstraints(for: containerView)
        
        if animated {
            containerView.transform = CGAffineTransform(translationX: self.navigationContentView.bounds.width, y: 0)

            UIView.animateWithCurve(duration: 0.4, x1: 0.2, y1: 1, x2: 0.36, y2: 1, animation: {
                containerView.transform = .identity
                self.navigationContentView.transform = CGAffineTransform(translationX: -60, y: 0)
                self.dimView.alpha = 1
            }, completion: {
                viewController.didMove(toParent: self)
            })
            
        }
        else {
            viewController.didMove(toParent: self)
        }
        
        
        self.containerView = containerView
        
    }
    
    public func pop(animated: Bool = true) {
        guard let containerView = self.containerView else { return }

        containerView.viewController.willMove(toParent: nil)
        
        if animated {
            self.navigationContentView.transform = CGAffineTransform(translationX: -60, y: 0)
            self.dimView.alpha = 1
            UIView.springAnimate(duration: animated ? 0.4 : 0, animations: {
                containerView.transform = CGAffineTransform(translationX: self.navigationContentView.bounds.width, y: 0)
                self.navigationContentView.transform = .identity
                self.dimView.alpha = 0
            }, completion: { _ in
                containerView.removeFromSuperview()
                containerView.viewController.removeFromParent()
                self.dimView.removeFromSuperview()
                self.containerView = nil
            })
        }
        else {
            self.navigationContentView.transform = .identity
            containerView.viewController.removeFromParent()
            containerView.removeFromSuperview()
            self.dimView.removeFromSuperview()
            self.containerView = nil
        }
        
    }
    
    private func setNavigationConstraints(for containerView: ContainerView) {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.widthAnchor.constraint(equalTo: self.navigationContentView.widthAnchor),
            containerView.heightAnchor.constraint(equalTo: self.navigationContentView.heightAnchor),
            containerView.centerXAnchor.constraint(equalTo: self.navigationContentView.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: self.navigationContentView.centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            dimView.widthAnchor.constraint(equalTo: self.navigationContentView.widthAnchor),
            dimView.heightAnchor.constraint(equalTo: self.navigationContentView.heightAnchor),
            dimView.centerXAnchor.constraint(equalTo: self.navigationContentView.centerXAnchor),
            dimView.centerYAnchor.constraint(equalTo: self.navigationContentView.centerYAnchor)
        ])
        
    }
    
    func interactionControllerDidBeginDragging(_ controller: NavigationInteractionController) {
        self.navigatedViewController?.viewDidBeginDragging()
    }
    
    func interactionControllerWillCommitDismissal(_ controller: NavigationInteractionController) {
        navigatedViewController?.willMove(toParent: nil)
    }
    
    func interactionControllerDidCommitDismissal(_ controller: NavigationInteractionController) {
        navigatedViewController?.removeFromParent()
        containerView?.removeFromSuperview()
        self.dimView.removeFromSuperview()
        self.containerView = nil
    }
    
}




// MARK: - NavigationInteractionController

protocol NavigationInteractionControllerDelegate: NavigationViewController {
    func interactionControllerDidBeginDragging(_ controller: NavigationInteractionController)
    func interactionControllerWillCommitDismissal(_ controller: NavigationInteractionController)
    func interactionControllerDidCommitDismissal(_ controller: NavigationInteractionController)
}

class NavigationInteractionController: NSObject {
    
    weak var delegate: NavigationInteractionControllerDelegate?
    
    let panGestureRecognizer = UIPanGestureRecognizer()
    
    override init() {
        super.init()
        
        self.panGestureRecognizer.addTarget(self, action: #selector(self.handleDismissalGesture(_:)))
        
    }
    
    @objc func handleDismissalGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
            case .began:
                self.delegate?.interactionControllerDidBeginDragging(self)
                self.dismissalGestureDidBegin(gesture)
                
            case .changed:
                self.dismissalGestureDidUpdate(gesture)
                
            case .ended, .cancelled:
                self.dismissalGestureDidEnd(gesture)
                
            default:
                break
        }
    }
    
    func dismissalGestureDidBegin(_ gesture: UIPanGestureRecognizer) {
        //
    }

    func dismissalGestureDidUpdate(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        let translation = gesture.translation(in: view).x
        let interactionDistance = self.interationDistance()
        
        var progress = interactionDistance == 0 ? 0 : (translation / interactionDistance)
        if progress < 0 { progress = 0 }
        
        self.updateDismissalInteraction(progress: progress, interactionDistance: interactionDistance)
    }

    func dismissalGestureDidEnd(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        let translation = gesture.translation(in: view).x
        let velocity = gesture.velocity(in: view).x
        
        let interactionDistance = self.interationDistance()
        
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
        guard let navigationViewController = self.delegate,
              let containerView = navigationViewController.containerView else { return }
        
        containerView.transform = CGAffineTransform(translationX: progress*interactionDistance, y: 0)
        navigationViewController.navigationContentView.transform = CGAffineTransform(translationX: -60 + (progress*60), y: 0)
        navigationViewController.dimView.alpha = 1 - progress
        
    }

    func cancelDismissalInteraction(velocity: CGFloat) {
        guard let navigationViewController = self.delegate,
              let containerView = navigationViewController.containerView else { return }
        
        let timingParameters = UISpringTimingParameters(
            dampingRatio: 1,
            initialVelocity: CGVector(dx: 0, dy: velocity)
        )
        
        let animator = UIViewPropertyAnimator(duration: 0.4, timingParameters: timingParameters)
        
        animator.addAnimations {
            containerView.transform = .identity
            navigationViewController.navigationContentView.transform = CGAffineTransform(translationX: -60, y: 0)
            navigationViewController.dimView.alpha = 1
        }
        
        animator.startAnimation()
    }

    func commitDismissalInteraction(velocity: CGFloat, interactionDistance: CGFloat) {
        guard let navigationViewController = self.delegate,
              let containerView = navigationViewController.containerView else { return }
        
        delegate?.interactionControllerWillCommitDismissal(self)
        
        let timingParameters = UISpringTimingParameters(
            dampingRatio: 1,
            initialVelocity: CGVector(dx: 0, dy: velocity)
        )
        
        let animator = UIViewPropertyAnimator(duration: 0.4, timingParameters: timingParameters)
        
        animator.addAnimations {
            containerView.transform = CGAffineTransform(translationX: interactionDistance, y: 0)
            navigationViewController.navigationContentView.transform = .identity
            navigationViewController.dimView.alpha = 0
        }
        
        animator.addCompletion { _ in
            self.delegate?.interactionControllerDidCommitDismissal(self)
        }
        
        animator.startAnimation()
        
    }

    // MARK: - Helpers

    /// Distance required for the view to be off screen
    func interationDistance() -> CGFloat {
        return self.delegate?.navigationContentView.bounds.width ?? 0
    }

    func springVelocity(distanceToTravel: CGFloat, gestureVelocity: CGFloat) -> CGFloat {
        return distanceToTravel == 0 ? 0 : gestureVelocity / distanceToTravel
    }
    
}


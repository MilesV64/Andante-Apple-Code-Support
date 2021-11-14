
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
    public var navigatedViewController: NavigatableViewController?
    
    public let dimView = UIView()
    
    private let interactionController = NavigationInteractionController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.interactionController.delegate = self
        
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
        
        viewController.willMove(toParent: self)
        self.view.addSubview(viewController.view)
        self.addChild(viewController)
        
        viewController.view.bounds.size = self.navigationContentView.bounds.size
        viewController.view.center = self.navigationContentView.center
        
        viewController.view.addGestureRecognizer(self.interactionController.panGestureRecognizer)
                
        self.navigationContentView.addSubview(self.dimView)
        
        self.setNavigationConstraints(for: viewController)
        
        if animated {
            viewController.view.transform = CGAffineTransform(translationX: self.navigationContentView.bounds.width, y: 0)

            UIView.animateWithCurve(duration: 0.4, x1: 0.2, y1: 1, x2: 0.36, y2: 1, animation: {
                viewController.view.transform = .identity
                self.navigationContentView.transform = CGAffineTransform(translationX: -60, y: 0)
                self.dimView.alpha = 1
            }, completion: {
                viewController.didMove(toParent: self)
            })
            
        }
        else {
            viewController.didMove(toParent: self)
        }
        
        
        self.navigatedViewController = viewController
        
    }
    
    public func pop(animated: Bool = true) {
        guard let viewController = self.navigatedViewController else { return }

        viewController.willMove(toParent: nil)
        
        if animated {
            self.navigationContentView.transform = CGAffineTransform(translationX: -60, y: 0)
            self.dimView.alpha = 1
            UIView.springAnimate(duration: animated ? 0.4 : 0, animations: {
                viewController.view.transform = CGAffineTransform(translationX: self.navigationContentView.bounds.width, y: 0)
                self.navigationContentView.transform = .identity
                self.dimView.alpha = 0
            }, completion: { _ in
                viewController.view.removeFromSuperview()
                viewController.removeFromParent()
                self.dimView.removeFromSuperview()
                self.navigatedViewController = nil
            })
        }
        else {
            self.navigationContentView.transform = .identity
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()
            self.dimView.removeFromSuperview()
            self.navigatedViewController = nil
        }
        
    }
    
    private func setNavigationConstraints(for viewController: NavigatableViewController) {
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            viewController.view.widthAnchor.constraint(equalTo: self.navigationContentView.widthAnchor),
            viewController.view.heightAnchor.constraint(equalTo: self.navigationContentView.heightAnchor),
            viewController.view.centerXAnchor.constraint(equalTo: self.navigationContentView.centerXAnchor),
            viewController.view.centerYAnchor.constraint(equalTo: self.navigationContentView.centerYAnchor)
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
        navigatedViewController?.view.removeFromSuperview()
        navigatedViewController?.removeFromParent()
        self.dimView.removeFromSuperview()
        self.navigatedViewController = nil
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
        if progress < 0 { progress /= (1.0 + abs(progress * 20)) }
        
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
              let vc = navigationViewController.navigatedViewController else { return }
        print(progress, interactionDistance)
        vc.view.transform = CGAffineTransform(translationX: progress*interactionDistance, y: 0)
        navigationViewController.navigationContentView.transform = CGAffineTransform(translationX: -60 + (progress*60), y: 0)
        navigationViewController.dimView.alpha = 1 - progress
                
    }

    func cancelDismissalInteraction(velocity: CGFloat) {
        guard let navigationViewController = self.delegate,
              let vc = navigationViewController.navigatedViewController else { return }
        
        let timingParameters = UISpringTimingParameters(
            dampingRatio: 1,
            initialVelocity: CGVector(dx: 0, dy: velocity)
        )
        
        let animator = UIViewPropertyAnimator(duration: 0.4, timingParameters: timingParameters)
        
        animator.addAnimations {
            vc.view.transform = .identity
            navigationViewController.navigationContentView.transform = CGAffineTransform(translationX: -60, y: 0)
            navigationViewController.dimView.alpha = 1
        }
        
        animator.startAnimation()
    }

    func commitDismissalInteraction(velocity: CGFloat, interactionDistance: CGFloat) {
        guard let navigationViewController = self.delegate,
              let vc = navigationViewController.navigatedViewController else { return }
        
        delegate?.interactionControllerWillCommitDismissal(self)
        
        let timingParameters = UISpringTimingParameters(
            dampingRatio: 1,
            initialVelocity: CGVector(dx: 0, dy: min(10, velocity))
        )
        
        let animator = UIViewPropertyAnimator(duration: 0.4, timingParameters: timingParameters)
        
        animator.addAnimations {
            vc.view.transform = CGAffineTransform(translationX: interactionDistance, y: 0)
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


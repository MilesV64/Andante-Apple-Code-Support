//
//  TransitionPopupViewController.swift
//  Andante
//
//  Created by Miles Vinson on 2/18/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class TransitionPopupViewController: PopupViewController {
    
    public var primaryView = PopupContentView()
    private var secondaryViews: [PopupContentView] = []
    
    enum ViewState {
        case primary, secondary
    }
    
    private var viewState: ViewState = .primary
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        primaryView.popupViewController = self
        
        contentView.addSubview(primaryView)
        
    }
    
    override func willDrag() {
        super.willDrag()
        primaryView.willDrag()
        secondaryViews.forEach { $0.willDrag() }
    }
    
    override func willClose() {
        super.willClose()
        primaryView.willDissapear()
        secondaryViews.forEach { $0.willDissapear() }
    }
    
    func preferredHeightForPrimaryView(for width: CGFloat) -> CGFloat {
        return 0
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let contentInset = layout == .compact ? self.view.safeAreaInsets : nil
        primaryView.contextualFrame = contentView.bounds
        primaryView.setSafeArea(contentInset)
        
        secondaryViews.forEach {
            $0.contextualFrame = contentView.bounds
            $0.setSafeArea(contentInset)
        }
        
    }
    
    override func layoutBGView(animateContent: Bool = true) {
        if viewState == .primary {
            preferredContentHeight = preferredHeightForPrimaryView(for: contentWidth)
        } else {
            preferredContentHeight = secondaryViews.last?.preferredHeight(for: contentWidth) ?? 0
        }
        
        super.layoutBGView(animateContent: animateContent)
    }
    
    public func push(_ view: PopupContentView, animateWithKeyboard: Bool = false) {
        view.popupViewController = self
        
        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        view.contextualFrame = contentView.bounds
        let contentInset = layout == .compact ? self.view.safeAreaInsets : nil
        view.setSafeArea(contentInset)
        self.contentView.addSubview(view)
        
        let oldView: PopupContentView
        
        if viewState == .secondary {
            oldView = secondaryViews.last!
        } else {
            oldView = primaryView
        }
        
        self.secondaryViews.append(view)
        self.viewState = .secondary
        
        view.didTransition(self)

        
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            oldView.alpha = 0
        } completion: { (complete) in }
        
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.93, initialSpringVelocity: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            oldView.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
            view.alpha = 1
            view.transform = .identity
            self.layoutBGView(animateContent: false)
            
        } completion: { (complete) in }
        

    }
    
    public func popSecondaryView() {
        let popView: PopupContentView
        let lastView: PopupContentView
        
        if secondaryViews.count > 1 {
            popView = secondaryViews.remove(at: secondaryViews.count - 1)
            lastView = secondaryViews[secondaryViews.count - 1]
        }
        else {
            viewState = .primary
            popView = secondaryViews.remove(at: 0)
            lastView = primaryView
        }
        
        popView.willDissapear()
        
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            popView.alpha = 0
        } completion: { (complete) in }
        
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.93, initialSpringVelocity: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            popView.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            lastView.alpha = 1
            lastView.transform = .identity
            self.layoutBGView(animateContent: false)
        } completion: { (complete) in
            popView.removeFromSuperview()
            popView.didDissapear()
        }
        
    }
    
}

//
//  PopupStackContentView.swift
//  Andante
//
//  Created by Miles on 10/29/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class PopupStackContentView: UIView {
    
    /// The ideal height of the view.
    /// - Parameter width: The width of the popup view. Use for calculating height if needed.
    public func preferredHeight(for width: CGFloat) -> CGFloat { return 0 }
    
    /// Weak reference to the containing popup view controller.
    /// Used to allow the content view to push/pop/hide
    public weak var popupViewController: PopupStackViewController?
    
    public var prefersHandleVisible: Bool { return true }
    
    public var dismissalHandlingScrollView: UIScrollView? { return nil }
    
    public func willAppear() {
        //
    }
    
    public func didAppear() {
        //
    }
    
    public func willDisappear() {
        //
    }
    
    public func didDisappear() {
        //
    }
}

//
//  CenterPickerViewController.swift
//  Andante
//
//  Created by Miles Vinson on 7/1/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class CenterPickerViewController: UIViewController, UIGestureRecognizerDelegate {
    
    private let dimView = UIView()
    
    private let outsideTap = UITapGestureRecognizer()
    
    /*
    Add custom views like date pickers to this view
     */
    public let contentView = UIView()
    
    public var contentSize = CGSize(width: 275, height: 220)
    
    public var closeAction: (()->Void)?
    
    public var animateWithKeyboard = false
    private var keyboardHeight: CGFloat = 0
    
    public var canTapToDismiss: Bool = true {
        didSet {
            outsideTap.isEnabled = canTapToDismiss
        }
    }
    
    convenience init(animateWithKeyboard: Bool) {
        self.init()
        self.animateWithKeyboard = animateWithKeyboard
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .clear
        
        dimView.alpha = 0
        dimView.backgroundColor = Colors.dynamicColor(light: UIColor.black.withAlphaComponent(0.2), dark: UIColor.black.withAlphaComponent(0.4))
        self.view.addSubview(dimView)
        
        outsideTap.delegate = self
        outsideTap.addTarget(self, action: #selector(close))
        dimView.addGestureRecognizer(outsideTap)
        
        contentView.backgroundColor = Colors.foregroundColor
        contentView.roundCorners(14)
        contentView.setShadow(radius: 18, yOffset: 4, opacity: 0.24, color: Colors.barShadowColor)
        contentView.alpha = 0
        self.view.addSubview(contentView)
        
        if animateWithKeyboard {
            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        }
        
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            self.keyboardHeight = 0
        } else {
            self.keyboardHeight = keyboardViewEndFrame.height
        }
        
        guard let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            print("Couldn't get animation duration")
            return
        }
        
        guard let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            print("Couldn't get animation curve")
            return
        }
        
        if animationDuration > 0 {
            UIView.animate(
                withDuration: animationDuration, delay: 0.0, options: UIView.AnimationOptions(rawValue: curve),
                animations: {
                    self.contentView.transform = .identity
                    self.contentView.alpha = 1
                    self.dimView.alpha = 1
                    self.viewDidLayoutSubviews()
                },
                completion: nil)
        }
        else {
            
            if notification.name != UIResponder.keyboardWillHideNotification && contentView.transform != .identity {
                contentView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }
            
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                self.contentView.transform = .identity
                self.contentView.alpha = 1
                self.dimView.alpha = 1
                self.viewDidLayoutSubviews()
            }, completion: nil)
        }
        

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        dimView.frame = self.view.bounds
        
        contentView.bounds.size = contentSize
        contentView.center = CGPoint(
            x: view.bounds.midX,
            y: min(view.bounds.midY, view.bounds.maxY - keyboardHeight - contentSize.height/2 - 50))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        contentView.bounds.size = contentSize
        contentView.center = self.view.bounds.center
        
        if animateWithKeyboard {
            self.contentView.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
            return
        }
        
        contentView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            self.contentView.transform = .identity
            self.contentView.alpha = 1
            self.dimView.alpha = 1
        }, completion: nil)
        
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == outsideTap {
            return dimView == touch.view
        }
        
        return true
    }
    
    @objc func close(withCloseAction: Bool = true) {
        UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseOut], animations: {
            self.contentView.transform = self.contentView.transform.concatenating(CGAffineTransform(scaleX: 0.95, y: 0.95))
            self.contentView.alpha = 0
            self.dimView.alpha = 0
        }) { (complete) in
            self.dismiss(animated: false, completion: {
                if withCloseAction {
                    self.closeAction?()
                }
            })
        }
    }
    
}

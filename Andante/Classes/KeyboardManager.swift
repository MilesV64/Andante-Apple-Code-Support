//
//  KeyboardManager.swift
//  Andante
//
//  Created by Miles on 10/29/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

protocol KeyboardObserver: AnyObject {
    func keyboardWillUpdate(_ keyboardManager: KeyboardManager, update: KeyboardManager.KeyboardUpdate)
}

class KeyboardManager: NSObject {
    
    enum KeyboardUpdate {
        case show
        case hide
        case changeFrame
    }
    
    static func startObserving() {
        // initializes the shared manager
        let _ = KeyboardManager.shared
    }
    
    static let shared = KeyboardManager()
    
    private(set) var keyboardHeight: CGFloat = 0
    
    fileprivate class WeakObserver {
        private(set) weak var value: KeyboardObserver?
        
        init(value: KeyboardObserver?) {
            self.value = value
        }
    }
    
    private var observers : [WeakObserver] = []
    
    func addObserver(_ observer: KeyboardObserver) {
        self.observers = self.observers.filter({ $0.value != nil }) // Trim
        self.observers.append( WeakObserver(value: observer) ) // Append
    }
    
    func removeObserver(_ observer: KeyboardObserver) {
        self.observers = self.observers.filter({
            guard let value = $0.value else {
                return false
            }
            return !(value === observer)
        })
    }
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc internal func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            self.keyboardHeight = keyboardRectangle.height
        }
        
        self.observers.compactMap({ $0.value }).forEach { $0.keyboardWillUpdate(self, update: .show) }
    }
    
    /// Called when the keyboard will change its frame due to events like opening emoji or toggling autocorrect.
    /// Not called when the frame changes to/from 0 as a result of opening/closing.
    @objc internal func keyboardWillChangeFrame(_ notification: Notification) {
        let currentHeight = self.keyboardHeight
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            self.keyboardHeight = keyboardRectangle.height
        }
        
        if
            currentHeight != 0,
            currentHeight != self.keyboardHeight,
            self.keyboardHeight != 0
        {
            self.observers.compactMap({ $0.value }).forEach { $0.keyboardWillUpdate(self, update: .changeFrame) }
        }
    }
    
    @objc internal func keyboardWillHide(_ notification: Notification) {
        self.keyboardHeight = 0
        
        self.observers.compactMap({ $0.value }).forEach { $0.keyboardWillUpdate(self, update: .hide) }
        
    }
    
}


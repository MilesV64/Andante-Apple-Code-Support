//
//  SettingsDetailViewController.swift
//  Andante
//
//  Created by Miles Vinson on 7/28/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class SettingsDetailViewController: ChildTransitionViewController {
    
    public let headerView = UIView()
    private let backButton = Button("chevron.left")
    private let titleLabel = UILabel()
    
    private let scrollView = UIScrollView()
    
    public var items: [SettingsDetailItem] = []
    private var itemHeight: CGFloat = 66
    
    override var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    convenience init(title: String) {
        self.init()
        self.title = title
    }
    
    public var backgroundColor: UIColor? {
        set {
            scrollView.backgroundColor = newValue
        }
        get {
            return scrollView.backgroundColor
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = Colors.backgroundColor
        scrollView.backgroundColor = Colors.backgroundColor
        scrollView.alwaysBounceVertical = true
        self.view.addSubview(scrollView)

        headerView.backgroundColor = Colors.backgroundColor
        self.view.addSubview(headerView)
        
        titleLabel.textColor = Colors.text
        titleLabel.font = Fonts.semibold.withSize(17)
        titleLabel.textAlignment = .center
        headerView.addSubview(titleLabel)
        
        backButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.didTapBack()
        }
        backButton.contentHorizontalAlignment = .left
        backButton.contentEdgeInsets.left = Constants.smallMargin - 1
        headerView.addSubview(backButton)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            self.scrollView.contentInset.bottom = 0
        } else {
            UIView.animate(withDuration: 0.25) {
                self.scrollView.contentInset.bottom = keyboardViewEndFrame.height - self.view.safeAreaInsets.bottom
                
                if let item = self.items.first(where: { (i) -> Bool in
                    return i.isFirstResponder
                }) {
                    let height = self.scrollView.frame.height - self.scrollView.contentInset.top - (keyboardViewEndFrame.height)
                    let scrollTopY = item.frame.maxY - height
                    let offset = -self.scrollView.contentInset.top + scrollTopY - CGFloat(1)
                    if offset > self.scrollView.contentOffset.y {
                        self.scrollView.setContentOffset(.init(x: 0, y: offset), animated: false)
                    }
                }
                
                
            }
            
        }
        
        scrollView.scrollIndicatorInsets = scrollView.contentInset

    }
    
    public func addItem(_ item: SettingsDetailItem) {
        items.append(item)
        scrollView.addSubview(item)
        view.setNeedsLayout()
    }
    
    public func removeAllItems() {
        items.forEach { $0.removeFromSuperview() }
        items.removeAll()
    }
    
    @objc func didTapBack() {
        self.close()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        headerView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 66)
        
        backButton.frame = CGRect(x: 0, y: 6, width: 50, height: 60)
        titleLabel.frame = CGRect(x: 50, y: 6, width: headerView.bounds.width - 100, height: 60)
        
        scrollView.frame = self.view.bounds
        scrollView.contentInset.top = headerView.bounds.height
        scrollView.verticalScrollIndicatorInsets.top = scrollView.contentInset.top
        
        var minY: CGFloat = 0
        for item in self.items {
            item.frame = CGRect(
                x: 0, y: minY,
                width: self.view.bounds.width,
                height: item.height)
            minY = item.frame.maxY
        }
        
        scrollView.contentSize.height = CGFloat(items.count)*itemHeight + headerView.bounds.height
        
    }
    
}


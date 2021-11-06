//
//  SettingsDetailViewController.swift
//  Andante
//
//  Created by Miles Vinson on 7/28/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class SettingsDetailViewController: ChildTransitionViewController, UIScrollViewDelegate {
    
    public let headerView = UIView()
    public let scrollView = UIScrollView()

    private let headerBG = Separator(position: .bottom)
    private let backButton = Button("chevron.left")
    private let titleLabel = UILabel()
    
    public let saveButton = UIButton(type: .system)
    
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
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        self.view.addSubview(scrollView)
        
        headerView.backgroundColor = .clear
        self.view.addSubview(headerView)
        
        self.headerBG.backgroundColor = Colors.foregroundColor
        self.headerBG.inset = .zero
        self.headerBG.setBarShadow()
        headerView.addSubview(headerBG)
        
        titleLabel.textColor = Colors.text
        titleLabel.font = Fonts.semibold.withSize(17)
        titleLabel.textAlignment = .center
        headerView.addSubview(titleLabel)
        
        self.saveButton.alpha = 0
        saveButton.setTitle("Save", color: Colors.orange, font: Fonts.semibold.withSize(17))
        saveButton.addTarget(self, action: #selector(self.handleSaveButton), for: .touchUpInside)
        headerView.addSubview(saveButton)
        
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.headerBG.setBarShadow()
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
    
    @objc private func handleSaveButton() {
        self.didTapSave()
    }
    
    public func didTapSave() {
        
    }
    
    public func setSaveButtonVisible(_ visible: Bool) {
        UIView.animate(withDuration: 0.1) {
            self.saveButton.alpha = visible ? 1 : 0
        }
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
        
        headerView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 80)
        headerBG.frame = headerView.bounds
        
        backButton.frame = CGRect(x: 5, y: 12, width: 50, height: 70)
        titleLabel.frame = CGRect(x: 50, y: 10, width: headerView.bounds.width - 100, height: 70)
        saveButton.frame = CGRect(x: headerView.bounds.maxX - 80 - 1, y: 20, width: 80, height: 50)
        
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
        
        scrollView.contentSize.height = max(
            scrollView.bounds.height - headerView.bounds.height,
            CGFloat(items.count)*itemHeight + headerView.bounds.height
        )
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        self.headerBG.alpha = offset / 12
    }
    
}

class FloatingHeaderView: UIView {
    
    public static let height: CGFloat = 80
    
    private let headerBG = Separator(position: .bottom)
    
    let backButton = Button("chevron.left")
    let titleLabel = UILabel()
    let handleView = HandleView()
    
    init(_ title: String) {
        super.init(frame: .zero)
        
        self.backgroundColor = Colors.backgroundColor
        self.addSubview(headerBG)
        
        self.headerBG.backgroundColor = Colors.foregroundColor
        self.headerBG.inset = .zero
        self.headerBG.setBarShadow()
        self.headerBG.alpha = 0
        self.addSubview(headerBG)
        
        titleLabel.text = title
        titleLabel.textColor = Colors.text
        titleLabel.font = Fonts.semibold.withSize(17)
        titleLabel.textAlignment = .center
        self.addSubview(titleLabel)
        
        backButton.contentHorizontalAlignment = .left
        backButton.contentEdgeInsets.left = Constants.smallMargin - 1
        self.addSubview(backButton)
        
        self.addSubview(handleView)
    }
    
    public func didScroll(_ scrollOffset: CGFloat) {
        self.headerBG.alpha = scrollOffset / 12
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        headerBG.frame = self.bounds
        
        backButton.frame = CGRect(x: 5, y: 12, width: 50, height: 70)
        titleLabel.frame = CGRect(x: 50, y: 10, width: self.bounds.width - 100, height: 70)
        
        let height = handleView.sizeThatFits(self.bounds.size).height
        handleView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: height)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

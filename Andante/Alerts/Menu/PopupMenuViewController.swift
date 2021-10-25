//
//  PopupMenuViewController.swift
//  Andante
//
//  Created by Miles Vinson on 3/21/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class PopupMenuViewController: UIViewController, UIGestureRecognizerDelegate {
    
    public var relativePoint = CGPoint()
    public var width: CGFloat?
    
    var minXConstraint: CGFloat?
    var maxXConstraint: CGFloat?
    
    public var shouldDimBackground = true
    
    private var selectedItem: MenuItemView? = nil
    
    private let escapeTap = UITapGestureRecognizer()
    
    private let touchGesture = UILongPressGestureRecognizer()
    private let touchFeedback = UISelectionFeedbackGenerator()
    private let selectFeedback = UIImpactFeedbackGenerator(style: .light)
    
    private let bgView = UIView()
    
    public var forceAbove = false
    public var forceLeft = false
    public var constrainToScreen = false
    public var delayCompletion = true
    public var showSelectedItemOnTap = false
    
    private var menuItems: [MenuItem] = []
    
    public var overrideStatusBarStyle: UIStatusBarStyle?
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return overrideStatusBarStyle ?? super.preferredStatusBarStyle
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.modalPresentationStyle = .overFullScreen

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var scrollView: UIScrollView?
    public func setScrollview(_ scrollView: UIScrollView) {
        self.scrollView = scrollView
        self.bgTouchView.addGestureRecognizer(scrollView.panGestureRecognizer)
        scrollView.panGestureRecognizer.addTarget(self, action: #selector(didScroll(_:)))
    }
    
    @objc func didScroll(_ gesture: UIPanGestureRecognizer) {
        self.hide()
    }
    
    private let bgTouchView = UIView()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .clear
        escapeTap.addTarget(self, action: #selector(didTapBackground))
       
        bgTouchView.backgroundColor = .clear
        self.view.addSubview(bgTouchView)
        
        bgTouchView.addGestureRecognizer(escapeTap)
        
        if traitCollection.userInterfaceStyle == .dark {
            bgView.setShadow(radius: 24, yOffset: 8, opacity: 0.35, color: .black)
        }
        else {
            bgView.setShadow(radius: 24, yOffset: 8, opacity: 0.25, color: Colors.darkerBarShadow)
        }
        
        bgView.backgroundColor = Colors.foregroundColor
        self.view.addSubview(bgView)

        bgView.roundCorners(14)
        
        touchGesture.minimumPressDuration = 0
        touchGesture.addTarget(self, action: #selector(handleTouch(_:)))
        touchGesture.delegate = self
        self.view.addGestureRecognizer(touchGesture)
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.userInterfaceStyle == .dark {
            bgView.setShadow(radius: 24, yOffset: 8, opacity: 0.35, color: .black)
        }
        else {
            bgView.setShadow(radius: 24, yOffset: 8, opacity: 0.25, color: Colors.darkerBarShadow)
        }
    }
    
    public func addItem(title: String, icon: UIImage?, handler: (()->Void)?, destructive: Bool = false) {
        let item = MenuItemView(icon: icon, title: title, handler: handler, destructive: destructive)
        self.addItem(item)
    }
    
    public func addItem(title: String, iconName: String, handler: (()->Void)?, destructive: Bool = false) {
        let icon = UIImage(name: iconName, pointSize: 19, weight: .medium)
        let item = MenuItemView(icon: icon, title: title, handler: handler, destructive: destructive)
        item.fixedIconSize = false
        self.addItem(item)
    }
    
    public func selectItem(at index: Int) {
        for (i, item) in menuItems.enumerated() {
            if let item = item as? MenuItemView {
                item.isSelected = i == index
            }
        }
    }
    
    public func addTitleItem(title: String) {
        addItem(MenuItemTitle(title: title))
    }
    
    public func addSwitchItem(title: String, isOn: Bool, handler: ((_:Bool)->Void)?) {
        addItem(MenuItemSwitch(title: title, isOn: isOn, handler: handler))
    }
    
    public func addSeparator() {
        addItem(MenuItemSeparator())
    }
    
    public func addSpacer(height: CGFloat = 16) {
        addItem(MenuItemSpacer(height: height))
    }
    
    public func getItem(at index: Int) -> MenuItemView? {
        if index >= 0 && index < menuItems.count {
            return menuItems[index] as? MenuItemView
        }
        return nil
    }
    
    public func removeIcons() {
        for item in self.menuItems {
            if let item = item as? MenuItemView {
                item.icon = nil
            }
        }
    }
    
    private func addItem(_ item: MenuItem) {
        menuItems.append(item)
        bgView.addSubview(item)
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        bgTouchView.frame = self.view.bounds
        
        let totalItemHeight = getTotalItemHeight()
        let topMargin: CGFloat = 7
        
        bgView.bounds.size = CGSize(width: width ?? 230, height: totalItemHeight + topMargin*2)
       
        let minX = minXConstraint ?? Constants.smallMargin/2
        let maxX = (maxXConstraint ?? self.view.bounds.maxX - Constants.smallMargin/2) - bgView.bounds.width
        let x = clamp(value: relativePoint.x - bgView.bounds.width/2, min: minX, max: maxX)
        
        let convPoint = relativePoint.x - x
        
        var yAnchor: CGFloat = 0
        if constrainToScreen {
            let frame = self.view.bounds.inset(by: self.view.safeAreaInsets).insetBy(dx: 0, dy: 20)
            let maxY = frame.maxY - bgView.bounds.height
            let relativeY = relativePoint.y
            let anchor = (relativeY - maxY)/bgView.bounds.height
            yAnchor = max(0, anchor)
        }
        else {
            if relativePoint.y > self.view.bounds.height * 0.7 || forceAbove {
                yAnchor = 1
            }
        }
        
        bgView.layer.anchorPoint = CGPoint(x: convPoint/bgView.bounds.width, y: yAnchor)
        
        bgView.center = CGPoint(
            x: relativePoint.x,
            y: relativePoint.y + (forceAbove ? -28 : 0))
            
        var minY: CGFloat = topMargin
        for (i, item) in menuItems.enumerated() {
            item.frame = CGRect(x: 0, y: minY, width: bgView.bounds.width, height: item.height)
            minY += item.height
            
            
            if let _ = item as? MenuItemSeparator {
                item.showSeparator = false
            }
            else if i + 1 < menuItems.count {
                if let _ = menuItems[i+1] as? MenuItemSeparator {
                    item.showSeparator = false
                }
                else {
                    item.showSeparator = true
                }
            }
            else {
                item.showSeparator = true
            }
            
            
        }
        
        menuItems.last?.showSeparator = false
        
    }
    
    private func getTotalItemHeight() -> CGFloat {
        var height: CGFloat = 0
        for item in self.menuItems {
            height += item.height
        }
        return height
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == escapeTap || gestureRecognizer == scrollView?.panGestureRecognizer {
            return touch.view == gestureRecognizer.view
        }
        else {
            return true
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func didTapBackground() {
        hide()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        bgView.alpha = 0
        bgView.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
        
        UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
            if self.shouldDimBackground {
                self.view.backgroundColor = Colors.dynamicColor(
                    light: UIColor.black.withAlphaComponent(0.03),
                    dark: UIColor.black.withAlphaComponent(0.1))
            }
            self.bgView.alpha = 1
            self.bgView.transform = .identity
        }, completion: nil)
        
    }
    
    private var overlayWindow: UIWindow?
    public func show(_ sender: UIViewController) {
        guard let overlayFrame = sender.view.window?.frame else { return }
        
        overlayWindow = UIWindow(frame: overlayFrame)
        
        overlayWindow?.windowLevel = .alert
        let overlayVC = self
        overlayWindow?.rootViewController = overlayVC
        overlayWindow?.isHidden = false
    }
    
    private var didHide = false
    public func hide(animated: Bool = true, ignoreSelectedItem: Bool = false) {
        if didHide { return }
        
        didHide = true
        
        if ignoreSelectedItem {
            selectedItem = nil
        }
        
        if let scrollView = self.scrollView {
            self.view.removeGestureRecognizer(scrollView.panGestureRecognizer)
            scrollView.addGestureRecognizer(scrollView.panGestureRecognizer)
        }

        if let selectedItem = selectedItem {
            selectFeedback.impactOccurred()
            if showSelectedItemOnTap {
                for item in menuItems {
                    if let item = item as? MenuItemView {
                        item.isSelected = item === selectedItem
                    }
                }
            }
        }
        
        if !delayCompletion {
            if let item = self.selectedItem {
                item.handler?()
            }
        }
        
        UIView.animate(withDuration: animated ? 0.25 : 0, delay: 0, options: .curveEaseOut, animations: {
            self.view.backgroundColor = .clear
            self.bgView.alpha = 0
            self.bgView.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
        }) {
            [weak self] _ in
            guard let self = self else { return }
            
            if self.delayCompletion {
                if let item = self.selectedItem {
                    item.handler?()
                }
            }
            
            self.overlayWindow?.rootViewController = nil
            if let gesture = self.scrollView?.panGestureRecognizer {
                gesture.removeTarget(self, action: #selector(self.didScroll(_:)))
                self.bgTouchView.removeGestureRecognizer(gesture)
            }
            self.scrollView = nil
            self.overlayWindow = nil
            
            for item in self.menuItems {
                if let item = item as? MenuItemView {
                    item.handler = nil
                }
            }
        }
    }
    
    deinit {
        let x = 10
        print("deinit")
    }
    
    @objc func handleTouch(_ gesture: UILongPressGestureRecognizer) {
        
        let location = gesture.location(in: self.view)
        
        if gesture.state == .began {
            touchFeedback.prepare()

            selectedItem = nil
            
            let convertedLocation = self.view.convert(location, to: bgView)
            for button in self.menuItems {
                if let button = button as? MenuItemView {
                    if button.frame.contains(convertedLocation) {
                        button.isHighlighted = true
                        selectedItem = button
                        break
                    }
                }
            }
        }
        else if gesture.state == .changed {
            var currentSelectedItem: MenuItemView?
            
            let convertedLocation = self.view.convert(location, to: bgView)
            for button in self.menuItems {
                if let button = button as? MenuItemView {
                    if button.frame.contains(convertedLocation) {
                        button.isHighlighted = true
                        currentSelectedItem = button
                    }
                    else {
                        button.isHighlighted = false
                    }
                }
            }
            
            if let button = currentSelectedItem {
                if button != selectedItem {
                    selectedItem = button
                    touchFeedback.selectionChanged()
                }
            }
            else if selectedItem != nil {
                selectedItem = nil
            }
            
        }
        else {
            if selectedItem != nil {
                hide()
            }
        }
        
    }
    
}

class MenuItem: UIView {
    
    public var height: CGFloat = 0
    public var fixedIconSize = true
    
    public let sep = Separator()
    
    public var showSeparator: Bool {
        get {
            return sep.isHidden == false
        }
        set {
            sep.isHidden = !newValue
        }
    }
    
    init() {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        
        
        sep.position = .bottom
        sep.inset = .zero
        //self.addSubview(sep)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sep.frame = self.bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MenuItemSpacer: MenuItem {
    
    init(height: CGFloat) {
        super.init()
        self.height = height
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MenuItemTitle: MenuItem {
    
    let label = UILabel()
    
    init(title: String) {
        super.init()
        
        self.height = 32
        
        label.text = title
        label.textColor = Colors.lightText
        label.font = Fonts.semibold.withSize(16)
        self.addSubview(label)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.frame = CGRect(
            x: Constants.margin, y: 4,
            width: self.bounds.width,
            height: self.bounds.height - 4)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MenuItemView: MenuItem {
    
    private let bgView = UIView()
    private let iconView = UIImageView()
    private let label = UILabel()
    
    public var icon: UIImage? {
        didSet {
            iconView.image = icon?.withRenderingMode(.alwaysTemplate)
            iconView.tintColor = Colors.text.withAlphaComponent(0.92)
        }
    }
    
    public var handler: (()->Void)?
        
    public var isHighlighted = false {
        didSet {
            if isSelected || isHighlighted {
                bgView.isHidden = false
            } else {
                bgView.isHidden = true
            }
        }
    }
    
    public var isSelected = false {
        didSet {
            if isSelected {
                bgView.isHidden = false
                bgView.backgroundColor = Colors.orange.withAlphaComponent(0.15)
                label.textColor = Colors.orange
                iconView.tintColor = Colors.orange
            } else {
                bgView.isHidden = !isHighlighted
                bgView.backgroundColor = Colors.extraLightColor
                label.textColor = Colors.text
                iconView.tintColor = Colors.text
            }
        }
    }
    
    convenience init(icon: UIImage?, title: String, color: UIColor?, handler: (()->Void)?) {
        self.init(icon: icon, title: title, handler: handler, destructive: false)
        label.textColor = color
        iconView.tintColor = color
    }
    
    init(icon: UIImage?, title: String, handler: (()->Void)?, destructive: Bool = false) {
        super.init()
        
        self.height = 44
        
        self.handler = handler
        
        bgView.backgroundColor = Colors.extraLightColor
        bgView.roundCorners(7)
        bgView.isHidden = true
        addSubview(bgView)
        
        iconView.image = icon?.withRenderingMode(.alwaysTemplate)
        self.addSubview(iconView)
 
        label.text = title
        label.font = Fonts.medium.withSize(16)
        self.addSubview(label)
        
        if destructive {
            label.textColor = Colors.red
            iconView.tintColor = Colors.red
        }
        else {
            label.textColor = Colors.text
            iconView.tintColor = Colors.text
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bgView.frame = self.bounds.insetBy(dx: 8, dy: 1)
                
        if fixedIconSize {
            iconView.frame = CGRect(
                center: CGPoint(x: self.bounds.width - 13 - Constants.margin, y: self.bounds.midY),
                size: CGSize(width: 24, height: 24))
        } else {
            iconView.sizeToFit()
            iconView.center = CGPoint(
                x: self.bounds.width - 13 - Constants.margin,
                y: self.bounds.midY)
        }
        
        label.frame = CGRect(x: Constants.margin,
                             y: 0, width: self.bounds.width,
                             height: self.bounds.height)
                        
    }
}

class MenuItemSwitch: MenuItem {
    
    private let label = UILabel()
    private let button = UISwitch()
    private var handler: ((_:Bool)->Void)?
    
    init(title: String, isOn: Bool, handler: ((_:Bool)->Void)?) {
        super.init()
        
        self.height = 46

        label.text = title
        label.font = Fonts.medium.withSize(16)
        label.textColor = Colors.text
        self.addSubview(label)
        
        button.isOn = isOn
        button.onTintColor = Colors.green
        button.addTarget(self, action: #selector(switchDidChangeValue(_:)), for: .valueChanged)
        self.handler = handler
        self.addSubview(button)
        
    }
    
    @objc func switchDidChangeValue(_ sender: UISwitch) {
        handler?(sender.isOn)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.sizeToFit()
        label.frame = CGRect(
            x: Constants.margin,
            y: 0,
            width: label.bounds.width,
            height: self.bounds.height-1)
        
        button.sizeToFit()
        button.frame.origin = CGPoint(
            x: self.bounds.maxX - button.bounds.width - Constants.smallMargin + 2,
            y: self.bounds.midY - button.bounds.height/2)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class MenuItemSeparator: MenuItem {
    
    override init() {
        super.init()
        
        self.height = 8
        self.backgroundColor = Colors.backgroundColor.withAlphaComponent(0.8)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

//
//  TutorialAlert.swift
//  Andante
//
//  Created by Miles Vinson on 9/30/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class TutorialAlertController: UIViewController, UIGestureRecognizerDelegate {
    
    public var relativePoint = CGPoint()
    public var contentSize: CGSize = CGSize(200)
        
    private let escapeTap = UITapGestureRecognizer()
    
    public let contentView = UIView()
    
    public var closeCompletion: (()->Void)?
    
    private let pointer = UIImageView()
    
    private let text = TitleBodyGroup()
    
    public var titleText: String? {
        didSet {
            text.titleLabel.text = titleText
        }
    }
    
    public var descriptionText: String? {
        didSet {
            text.textView.text = descriptionText
        }
    }
    
    public let doneButton = PushButton()
    
    enum Position {
        case topMiddle, bottomRight
    }
    
    public var position: Position = .bottomRight
        
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
        escapeTap.addTarget(self, action: #selector(didTapBackground))
        escapeTap.delegate = self
        self.view.addGestureRecognizer(escapeTap)
        
        contentView.backgroundColor = Colors.foregroundColor
        
        if traitCollection.userInterfaceStyle == .dark {
            contentView.setShadow(radius: 12, yOffset: 3, opacity: 0.3, color: .black)
        }
        else {
            contentView.setShadow(radius: 12, yOffset: 3, opacity: 0.16, color: Colors.barShadowColor)
        }
        
        self.view.addSubview(contentView)
        
        pointer.image = UIImage(named: "pointer")
        pointer.setImageColor(color: Colors.foregroundColor)
        contentView.addSubview(pointer)
        
        text.textAlignment = .center
        text.padding = 3
        
        text.titleLabel.font = Fonts.bold.withSize(17)
        text.titleLabel.textColor = Colors.text
        
        text.textView.font = Fonts.regular.withSize(16)
        text.textView.textColor = Colors.lightText
        
        contentView.addSubview(text)
        
        doneButton.backgroundColor = Colors.orange
        doneButton.setTitle("Got it", color: Colors.white, font: Fonts.medium.withSize(16))
        doneButton.cornerRadius = 10
        doneButton.buttonView.setShadow(radius: 6, yOffset: 3, opacity: 0.06)
        doneButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.hide()
        }
        contentView.addSubview(doneButton)
                
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.userInterfaceStyle == .dark {
            contentView.setShadow(radius: 12, yOffset: 3, opacity: 0.3, color: .black)
        }
        else {
            contentView.setShadow(radius: 12, yOffset: 3, opacity: 0.16, color: Colors.barShadowColor)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
                
        let textHeight = text.sizeThatFits(
            CGSize(width: 240, height: self.view.bounds.height)
        ).height
        let buttonHeight: CGFloat = 42
        
        contentSize.width = 240
        contentSize.height = textHeight + buttonHeight + 30 + 16 + 30
        
        text.frame = CGRect(
            x: 0, y: 30,
            width: contentSize.width,
            height: textHeight)
        
        let buttonWidth: CGFloat = 100
        doneButton.frame = CGRect(
            x: contentSize.width/2 - buttonWidth/2,
            y: text.frame.maxY + 16,
            width: buttonWidth, height: buttonHeight)
        
        contentView.bounds.size = contentSize
        
        let minX = Constants.smallMargin/2
        let maxX = (self.view.bounds.maxX - Constants.smallMargin/2) - contentView.bounds.width
        let x = clamp(value: relativePoint.x - contentView.bounds.width/2, min: minX, max: maxX)
        let yAnchor: CGFloat = position == .bottomRight ? 1 : 0
        
        let convPoint = relativePoint.x - x
        
        contentView.layer.anchorPoint = CGPoint(x: convPoint/contentView.bounds.width, y: yAnchor)
        
        contentView.center = CGPoint(
            x: relativePoint.x,
            y: relativePoint.y)
        
        pointer.bounds.size = CGSize(30)
        pointer.center = CGPoint(
            x: contentView.bounds.width*contentView.layer.anchorPoint.x,
            y: contentView.bounds.height*contentView.layer.anchorPoint.y)
        
        pointer.transform = CGAffineTransform(
            rotationAngle: position == .topMiddle ? CGFloat.pi : 0)
            
        contentView.roundCorners(16)
                
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == escapeTap {
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
        contentView.alpha = 0
        contentView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        
        UIView.animate(withDuration: 0.7, delay: 0.2, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.curveEaseInOut], animations: {
            self.view.backgroundColor = Colors.dynamicColor(light: UIColor.black.withAlphaComponent(0.05), dark: UIColor.black.withAlphaComponent(0.16))
            self.contentView.alpha = 1
            self.contentView.transform = .identity
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
    
    public func hide(animated: Bool = true) {
        closeCompletion?()
        UIView.animate(withDuration: animated ? 0.25 : 0, delay: 0, options: .curveEaseOut, animations: {
            self.view.backgroundColor = .clear
            self.contentView.alpha = 0
            self.contentView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }) { (_) in
            self.overlayWindow = nil
        }
    }
    
}

extension TutorialAlertController {
    
    static func SessionsTutorial() -> TutorialAlertController {
        let alert = TutorialAlertController()
        alert.titleText = "Welcome to Andante!"
        alert.descriptionText = "You can start a practice session by tapping the music note button.\n\nYou can also press and hold to manually add a session!"
        return alert
    }
    
    static func GoalTutorial() -> TutorialAlertController {
        let alert = TutorialAlertController()
        alert.titleText = "Daily Practice Goal"
        alert.descriptionText = "These rings show your daily practice goal progress.\n\nTap the rings to see more and adjust your daily goal."
        return alert
    }
    
}

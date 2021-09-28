//
//  PushButton.swift
//  Timer
//
//  Created by Miles Vinson on 5/1/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import UIKit

class Button: CustomButton {
    
    convenience init(_ iconName: String) {
        self.init()
        
        self.setImage(
            UIImage(name: iconName, pointSize: 17, weight: .bold)?
                .withRenderingMode(.alwaysTemplate), for: .normal)
        
        self.tintColor = Colors.lightText
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView?.contextualFrame = self.imageView?.frame ?? .zero
    }
    
    override init() {
        super.init()
        
        
        self.highlightAction = {
            [weak self] isHighlighted in
            guard let self = self else { return }
            
            if isHighlighted {
                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [.curveEaseOut], animations: {
                    self.imageView?.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
                    self.alpha = 0.65
                }, completion: nil)
            }
            else {
                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                    self.imageView?.transform = .identity
                    self.alpha = 1
                }, completion: nil)
            }
            
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class PushButton: CustomButton {
    
    public let buttonView = UIButton()
                
    public var transformScale: CGFloat = 0.94
    
    public var cornerRadius: CGFloat = 0 {
        didSet {
            buttonView.roundCorners(cornerRadius)
        }
    }
    
    override var backgroundColor: UIColor? {
        get {
            return buttonView.backgroundColor
        }
        set {
            if newValue != UIColor.clear {
                buttonView.backgroundColor = newValue
            }
        }
    }
    
    public var image: UIImage? {
        get {
            return buttonView.image(for: .normal)
        }
        set {
            buttonView.setImage(newValue, for: .normal)
        }
    }
    
    public var imageColor: UIColor? {
        didSet {
            buttonView.setImage(self.image?.withRenderingMode(.alwaysTemplate), for: .normal)
            buttonView.tintColor = imageColor
        }
    }
    
    public var imageInsets: UIEdgeInsets {
        get {
            return buttonView.contentEdgeInsets
        }
        set {
            buttonView.contentEdgeInsets = newValue
        }
    }
        
    public var inset: UIEdgeInsets = .zero {
        didSet {
            setNeedsLayout()
        }
    }
    
    /**
     If set, transforms this view only
     */
    public var pushableView: UIView?
    private var pushView: UIView {
        return pushableView ?? buttonView
    }
    
    public var extraHighlightAction: ((Bool)->Void)?
    
    private var savedBackgroundColor: UIColor?
    
    override init() {
        super.init()
        
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = true
        
        self.addSubview(buttonView)
        buttonView.isUserInteractionEnabled = false
        buttonView.contentHorizontalAlignment = .center
        buttonView.contentVerticalAlignment = .center
        buttonView.imageView?.contentMode = .scaleAspectFit
        
        self.highlightAction = {
            [weak self] isHighlighted in
            guard let self = self else { return }
            
            if isHighlighted {
                UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState], animations: {
                    self.pushView.transform = CGAffineTransform(scaleX: self.transformScale, y: self.transformScale)
                }, completion: nil)
            }
            else {
                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState], animations: {
                    self.pushView.transform = .identity
                }, completion: nil)
            }
            self.extraHighlightAction?(isHighlighted)
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        buttonView.bounds = self.bounds.inset(by: inset)
        buttonView.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        
    }
    
    override func addSubview(_ view: UIView) {
        if view === buttonView {
            super.addSubview(view)
        }
        else {
            self.buttonView.addSubview(view)
        }
    }
    
    override func insertSubview(_ view: UIView, at index: Int) {
        self.buttonView.insertSubview(view, at: index)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class ActionButton: UIView, UIGestureRecognizerDelegate {
    
    private let touchGesture = UILongPressGestureRecognizer()
    private var animator: UIViewPropertyAnimator?
    
    private var touchPoint: CGPoint?
    private var isTouching = false
    
    private var completion: (()->Void)?
    
    public var longPressCompletion: (() -> Void)?
    
    public var delayCompletion: Bool = false
    
    public var transformScale: CGFloat = 0.92
    
    public var cornerRadius: CGFloat = 0 {
        didSet {
            buttonView.roundCorners(cornerRadius)
        }
    }
    
    public var isGestureEnabled: Bool {
        set {
            touchGesture.isEnabled = newValue
        }
        get {
            return touchGesture.isEnabled
        }
    }
    
    override var backgroundColor: UIColor? {
        get {
            return buttonView.backgroundColor
        }
        set {
            if newValue != UIColor.clear {
                buttonView.backgroundColor = newValue
            }
        }
    }
    
    public let buttonView = UIButton()
    
    public var inset: UIEdgeInsets = .zero {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var canLongPress: Bool = false {
        didSet {
            longPressGesture.isEnabled = canLongPress
        }
    }
    
    private let longPressGesture = UILongPressGestureRecognizer()
    private let longPressFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    /**
     If set, transforms this view only
     */
    public var pushableView: UIView?
    private var pushView: UIView {
        return pushableView ?? buttonView
    }
    
    init() {
        super.init(frame: .zero)
        
        initializeView()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initializeView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        buttonView.bounds = self.bounds.inset(by: inset)
        buttonView.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
                        
    }
    
    override func addSubview(_ view: UIView) {
        if view === buttonView {
            super.addSubview(view)
        }
        else {
            self.buttonView.addSubview(view)
        }
    }
    
    override func insertSubview(_ view: UIView, at index: Int) {
        self.buttonView.insertSubview(view, at: index)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
        
    var test = false
    @objc func didLongPress() {
        
        if test {
            return
        }
        else {
            test = true
        }
        
        longPressFeedback.impactOccurred()
        
        touchPoint = nil
        
        longPressCompletion?()
        
        touchUp(false)
    }
    
}

//MARK: Initialize
private extension ActionButton {
    func initializeView() {
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = true
        
        self.addSubview(buttonView)
        buttonView.isUserInteractionEnabled = false
        buttonView.contentHorizontalAlignment = .center
        buttonView.contentVerticalAlignment = .center
        buttonView.imageView?.contentMode = .scaleAspectFit
        
        touchGesture.addTarget(self, action: #selector(handleGesture(_:)))
        touchGesture.delegate = self
        touchGesture.minimumPressDuration = 0
        self.addGestureRecognizer(touchGesture)
        
        longPressGesture.addTarget(self, action: #selector(didLongPress))
        longPressGesture.delegate = self
        longPressGesture.minimumPressDuration = 0.25
        longPressGesture.isEnabled = false
        self.addGestureRecognizer(longPressGesture)
    }
}

//MARK: Layouts
private extension ActionButton {
    
}

//MARK: Private methods
private extension ActionButton {

    @objc func handleGesture(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            longPressFeedback.prepare()
            test = false
            isTouching = true
            touchPoint = sender.location(in: self)
            touchDown()
        case .changed:
            let rect = self.bounds.inset(by: UIEdgeInsets(-14))
            if rect.contains(sender.location(in: self)) == false {
                touchPoint = nil
                sender.isEnabled = false
                sender.isEnabled = true
            }
        case .cancelled:
            touchUp(false)
        case .ended:
            isTouching = false
            if let _ = touchPoint {
                //if touchPoint is not nil, the touch ended naturally
                touchUp(true)
            }
            else {
                //if touchPoint is nil, the touch was cancelled because of distance
                touchUp(false)
            }
        default:
            touchUp(false)
        }
    }
    
    
    
    
}

//MARK: Public methods
extension ActionButton {
    
    func setCompletion(_ completion: (()->Void)?) {
        self.completion = completion
    }
    
    func touchDown() {
        animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.6, animations: {
            self.pushView.transform = CGAffineTransform(scaleX: self.transformScale,
            y: self.transformScale)
        })
        
        animator?.startAnimation()
        
    }
    
    func touchUp(_ successful: Bool) {
        if buttonView.transform == .identity {
            if successful {
                completion?()
            }
            return
        }
        
        if successful {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                self.pushView.transform = .identity
            }, completion: { (complete) in
                if self.delayCompletion {
                    self.completion?()
                }
            })
        }
        else {
            UIView.animate(withDuration: 0.2) {
                self.pushView.transform = .identity
            }
        }
        
        if successful && !delayCompletion {
            completion?()
        }
        
    }
}

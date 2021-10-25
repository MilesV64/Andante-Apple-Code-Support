//
//  OnboardingViewController.swift
//  Andante
//
//  Created by Miles Vinson on 8/9/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class OnboardingViewController: UIViewController {
    
    static var buttonWidth: CGFloat {
        return UIScreen.main.bounds.width < 375 ? 288 : 320
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let initialView = InitialView()
    private let nameView = ProfileNameView()
    private let iconView = ProfileIconView()
    
    private var iconName = ""
    private var didEditIcon = false
    
    private let button = PushButton()
    private var keyboardHeight: CGFloat = 0

    private var phase = 0
    
    private let backButton = Button("chevron.left")
    
    /// If true, does not save the newly created profile
    public var isForTesting: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = Colors.foregroundColor
        
        self.view.addSubview(initialView)
        
        nameView.alpha = 0
        nameView.delegate = self
        self.view.addSubview(nameView)
        
        iconView.alpha = 0
        iconView.action = {
            [weak self] iconName in
            guard let self = self else { return }
            
            self.didEditIcon = true
            
            self.button.isUserInteractionEnabled = true
            UIView.animate(withDuration: 0.25) {
                self.button.backgroundColor = Colors.orange
            }
            
            self.iconName = iconName
            
        }
        self.view.addSubview(iconView)
        
        button.setTitle("Get Started", color: Colors.white, font: Fonts.medium.withSize(17))
        button.cornerRadius = 14
        button.backgroundColor = Colors.orange
        button.buttonView.setButtonShadow()
        button.alpha = 0
        button.transform = CGAffineTransform(translationX: 0, y: 20)
        button.action = {
            [weak self] in
            guard let self = self else { return }
            self.didTapButton()
        }
        self.view.addSubview(button)
        
        backButton.alpha = 0
        backButton.contentHorizontalAlignment = .left
        backButton.contentEdgeInsets.left = Constants.smallMargin
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        self.view.addSubview(backButton)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        initialView.animate()
        
        UIView.animateWithCurve(duration: 1, delay: 1.6,
                   curve: UIView.CustomAnimationCurve.exponential.easeOut,
                   animation: {
                   self.button.alpha = 1
                   self.button.transform = .identity
               }, completion: nil)
        
    }
    
    @objc func didTapBack() {
        self.button.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.35) {
            self.iconView.alpha = 0
            self.iconView.transform = CGAffineTransform(translationX: self.view.bounds.width, y: 0)
            self.nameView.alpha = 1
            self.nameView.transform = .identity
            self.backButton.alpha = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            [weak self] in
            guard let self = self else { return }
            self.phase = 1

            self.nameView.becomeFirstResponder()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            [weak self] in
            guard let self = self else { return }
            
            UIView.transition(with: self.button, duration: 0.15, options: [.transitionCrossDissolve], animations: {
                if self.nameView.name == "" {
                    self.button.backgroundColor = Colors.lightText
                }
                else {
                    self.button.backgroundColor = Colors.orange
                    self.button.isUserInteractionEnabled = true
                }
                self.button.setTitle("Continue", for: .normal)
            }, completion: nil)
            
        }
        
    }
    
    private func didTapButton() {
        
        if phase == 0 {
            button.isUserInteractionEnabled = false
            
            phase = 1
            
            nameView.transform = CGAffineTransform(translationX: self.view.bounds.width, y: 0)
            
            UIView.animateWithCurve(duration: 0.7, delay: 0,
                curve: UIView.CustomAnimationCurve.cubic.easeInOut,
                animation: {
                    self.nameView.alpha = 1
                    self.nameView.transform = .identity
                    self.initialView.alpha = 0
                    self.initialView.transform = CGAffineTransform(translationX: -self.view.bounds.width, y: 0)
            }, completion: nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                [weak self] in
                guard let self = self else { return }
                
                UIView.transition(with: self.button, duration: 0.25, options: [.transitionCrossDissolve], animations: {
                    if self.nameView.name == "" {
                        self.button.backgroundColor = Colors.lightText
                    }
                    else {
                        self.button.isUserInteractionEnabled = true
                    }
                    self.button.setTitle("Continue", for: .normal)
                }, completion: nil)
                
            }
               
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                [weak self] in
                guard let self = self else { return }
                self.nameView.becomeFirstResponder()
            }
            
        }
        else if phase == 1 {
            self.button.isUserInteractionEnabled = false
            phase = 2
            
            nameView.resignFirstResponder()
            
            if !didEditIcon, let iconName = getIconFromName() {
                self.iconName = iconName
                iconView.initialIcon = iconName
            }
            
            iconView.transform = CGAffineTransform(translationX: self.view.bounds.width, y: 0)
            
            UIView.animateWithCurve(duration: 0.7, delay: 0,
                curve: UIView.CustomAnimationCurve.cubic.easeInOut,
                animation: {
                    self.iconView.alpha = 1
                    self.iconView.transform = .identity
                    self.nameView.alpha = 0
                    self.nameView.transform = CGAffineTransform(translationX: -self.view.bounds.width, y: 0)
                    self.backButton.alpha = 1
                    self.viewDidLayoutSubviews()
            }, completion: nil)
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                [weak self] in
                guard let self = self else { return }
                
                UIView.transition(with: self.button, duration: 0.25, options: [.transitionCrossDissolve], animations: {
                    if self.iconName == "" {
                        self.button.backgroundColor = Colors.lightText
                    }
                    else {
                        self.button.isUserInteractionEnabled = true
                    }
                    self.button.setTitle("Done", for: .normal)
                }, completion: nil)
            }
            
            
        }
        else if phase == 2 {
            phase = 3
            
            if self.isForTesting {
                self.dismiss(animated: true, completion: nil)
                
                self.navigationController?.transitionCoordinator?.animate(alongsideTransition: { context in
                    // animations
                }, completion: { context in
                    // completion
                })
                
            }
            else {
                let profile = CDProfile(context: DataManager.context)
                DataManager.obtainPermanentID(for: profile)
                profile.name = nameView.name
                profile.iconName = iconName
                CDProfile.saveProfile(profile)
                User.setActiveProfile(profile)
                User.reloadData()
                
                DataManager.saveContext()
                
                if let container = self.presentingViewController as? AndanteViewController {
                    container.didChangeProfile(profile)
                    container.animate()
                }
                
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if flag {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
                self.view.alpha = 0
                self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            } completion: { (complete) in
                super.dismiss(animated: false, completion: nil)
            }
        }
        else {
            super.dismiss(animated: false, completion: nil)
        }
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        if notification.name == UIResponder.keyboardWillHideNotification {
            self.keyboardHeight = 0
        } else {
            let keyboardScreenEndFrame = keyboardValue.cgRectValue
            let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

            keyboardHeight = keyboardViewEndFrame.height
        }

        nameView.keyboardHeight = keyboardHeight
        
        UIView.animate(withDuration: 0.25) {
            self.viewDidLayoutSubviews()
            self.nameView.layoutSubviews()
        }

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let width = min(self.view.bounds.width, 400)
        let margin = Constants.margin + (self.view.bounds.width - width)/2
        
        let frame = self.view.bounds.inset(by: self.view.safeAreaInsets).inset(by: UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0))
        
        let buttonSize = CGSize(width: self.view.bounds.width - margin*2, height: 50)
        button.cornerRadius = 25
        
        backButton.frame = CGRect(
            x: 0, y: self.view.safeAreaInsets.top,
            width: 60, height: 48)
        
        initialView.contextualFrame = frame
        initialView.margin = margin
        
        nameView.margin = margin
        nameView.keyboardHeight = keyboardHeight
        nameView.contextualFrame = frame
        
        var bottomOffset: CGFloat = 16
        if frame.height > 820 {
            bottomOffset = frame.height*0.04
        }
        
        iconView.contextualFrame = CGRect(
            from: CGPoint(x: 0, y: self.view.safeAreaInsets.top),
            to: CGPoint(x: self.view.bounds.maxX, y: self.view.bounds.maxY - self.view.safeAreaInsets.bottom - 16 - buttonSize.height - bottomOffset))
        
        iconView.margin = margin
                
        if keyboardHeight == 0 {
            button.contextualFrame = CGRect(
                x: frame.midX - buttonSize.width/2,
                y: self.view.bounds.maxY - self.view.safeAreaInsets.bottom - buttonSize.height - bottomOffset,
                width: buttonSize.width,
                height: buttonSize.height)
        }
        else {
            button.contextualFrame = CGRect(
                x: frame.midX - buttonSize.width/2,
                y: self.view.bounds.maxY - keyboardHeight - buttonSize.height - 16,
                width: buttonSize.width,
                height: buttonSize.height)
        }
        
        
    }
    
    func getIconFromName() -> String? {
        switch nameView.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) {
        case "violin": return "violin"
        case "viola": return "violin"
        case "cello": return "cello"
        case "bass": return "cello"
        case "harp": return "harp"
        case "guitar": return "acoustic-guitar"
        case "ukulele": return "ukulele"
        case "piano": return "piano"
        case "accordion": return "accordion"
        case "kalimba": return "kalimba"
        case "singing": return "singing"
        case "voice": return "singing"
        case "opera": return "singing"
        case "electric guitar": return "electric-guitar"
        case "flute": return "flute"
        case "piccolo": return "flute"
        case "oboe": return "oboe"
        case "english horn": return "oboe"
        case "clarinet": return "clarinet"
        case "bass clarinet": return "clarinet"
        case "recorder": return "recorder"
        case "bassoon": return "bassoon"
        case "contrabassoon": return "bassoon"
        case "trumpet": return "trumpet"
        case "trombone": return "trombone"
        case "horn": return "french-horn"
        case "french horn": return "french-horn"
        case "tuba": return "tuba"
        case "euphonium": return "tuba"
        case "saxophone": return "saxophone"
        case "snare": return "snare-drum"
        case "timpani": return "timpani"
        case "xylophone": return "xylophone"
        case "marimba": return "marimba"
        case "drums": return "drum-set"
        case "percussion": return "snare-drum"
        case "conducting": return "conducting-baton"
        case "composing": return "composing"
        case "composition": return "composing"
        case "production": return "synthesizer"
        case "producing": return "synthesizer"
        case "synth": return "synthesizer"
        case "synthesizer": return "synthesizer"
        case "music": return "music"
        case "painting": return "paint-brush"
        case "drawing": return "paint-brush"
        case "art": return "paint-brush"
        case "writing": return "pen"
        case "design": return "pen"
        case "banjo": return "banjo"
        default: return nil
        }
    }
    
}

extension OnboardingViewController: ProfileNameViewDelegate {
    
    func nameDidBecomeValid() {
        
        button.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.25) {
            self.button.backgroundColor = Colors.orange
        }
            
    }
    
    func nameDidBecomeInvalid() {
        
        button.isUserInteractionEnabled = false
        self.button.backgroundColor = Colors.lightText
        
    }
    
}


class InitialView: UIView {
    
    private let illustrationImg = UIImageView()
    private let titleLabel = UILabel()
    private let textView = UITextView()
    
    public var margin: CGFloat = 0
    
    init() {
        super.init(frame: .zero)
        
        illustrationImg.image = UIImage(named: "OnboardingIllustration")
        illustrationImg.alpha = 0
        self.addSubview(illustrationImg)
        
        let attStr = NSMutableAttributedString(string: "Welcome to\n", font: Fonts.bold.withSize(38), color: Colors.text)
        attStr.append(NSAttributedString(string: "Andante", font: Fonts.heavy.withSize(38), color: Colors.orange))
        titleLabel.attributedText = attStr
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.alpha = 0
        titleLabel.transform = CGAffineTransform(translationX: 0, y: 40)
        self.addSubview(titleLabel)
        
        textView.attributedText = NSAttributedString(string: "Achieve calm, focused practice with the help of a minimal but effective practice journal.", font: Fonts.medium.withSize(18), color: Colors.lightText, lineSpacing: 8)
        textView.isUserInteractionEnabled = false
        
        textView.textAlignment = .center
        textView.alpha = 0
        textView.transform = CGAffineTransform(translationX: 0, y: 70)
        textView.backgroundColor = .clear
        self.addSubview(textView)
        
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public func animate() {
        UIView.animateWithCurve(duration: 2, delay: 0.5,
            curve: UIView.CustomAnimationCurve.exponential.easeOut,
            animation: {
            self.illustrationImg.alpha = 1
        }, completion: nil)
        
        UIView.animateWithCurve(duration: 1.2, delay: 1,
            curve: UIView.CustomAnimationCurve.exponential.easeOut,
            animation: {
            self.titleLabel.alpha = 1
            self.titleLabel.transform = .identity
        }, completion: nil)
        
        UIView.animateWithCurve(duration: 1.2, delay: 1,
            curve: UIView.CustomAnimationCurve.exponential.easeOut,
            animation: {
            self.textView.alpha = 1
            self.textView.transform = .identity
        }, completion: nil)
        
       
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let frame = self.bounds.insetBy(dx: margin, dy: 0)
        let spacing: CGFloat = self.bounds.height * 0.035
        
        textView.textContainerInset = UIEdgeInsets(
            top: 0, left: -5, bottom: 0, right: -5)
        
        let titleSize = titleLabel.sizeThatFits(frame.size)
        let descriptionSize = textView.sizeThatFits(frame.size)
        let buttonSize = CGSize(width: frame.width, height: 50)
        let imgSpace: CGFloat = frame.height - titleSize.height - descriptionSize.height - buttonSize.height - spacing*3
        
        let totalHeight = titleSize.height + descriptionSize.height + buttonSize.height + imgSpace + spacing*3
        
        let minY = frame.midY - totalHeight/2
        
        let imgHeight = min(imgSpace, 260)
        illustrationImg.contextualFrame = CGRect(
            x: frame.midX - imgHeight/2,
            y: minY + imgSpace/2 - imgHeight/2,
            width: imgHeight,
            height: imgHeight).integral
        
        titleLabel.contextualFrame = CGRect(
            x: frame.midX - titleSize.width/2,
            y: illustrationImg.frame.maxY + spacing - 8,
            width: titleSize.width,
            height: titleSize.height).integral

        textView.contextualFrame = CGRect(
            x: frame.minX,
            y: titleLabel.frame.maxY + spacing - 4,
            width: frame.width,
            height: descriptionSize.height).integral

        
    }
}

protocol ProfileNameViewDelegate: AnyObject {
    func nameDidBecomeValid()
    func nameDidBecomeInvalid()
}

class ProfileNameView: UIView, UITextFieldDelegate {
    
    class CenteredTextField: UITextField {
        override func caretRect(for position: UITextPosition) -> CGRect {
            if self.hasText {
                return super.caretRect(for: position)
            } else {
                let rect = super.caretRect(for: position)
                
                return CGRect(
                    x: self.bounds.midX - (rect.width/2),
                    y: rect.minY,
                    width: rect.width,
                    height: rect.height)
            }
        }
    }
    
    public weak var delegate: ProfileNameViewDelegate?
    
    private let titleLabel = UILabel()
    private let textField = CenteredTextField()
    
    public var margin: CGFloat = 0
    public var keyboardHeight: CGFloat = 0
    
    public var name: String {
        return textField.text ?? "Profile"
    }
    
    private var isValid = false
    
    init() {
        super.init(frame: .zero)
        
        let attStr = NSMutableAttributedString(string: "What are you\n", font: Fonts.bold.withSize(32), color: Colors.text)
        attStr.append(NSAttributedString(string: "practicing?", font: Fonts.heavy.withSize(32), color: Colors.orange))
        titleLabel.attributedText = attStr
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        self.addSubview(titleLabel)
        
        textField.tintColor = Colors.orange
        textField.textColor = Colors.text
        textField.font = Fonts.medium.withSize(28)
        textField.textAlignment = .center
        textField.attributedPlaceholder = NSAttributedString(string: "e.g. Piano, Guitar", attributes: [
            .foregroundColor : Colors.extraLightText
        ])
//        textField.layer.borderColor = Colors.lightColor.cgColor
//        textField.layer.borderWidth = 2
//        textField.roundCorners(12)
        textField.setPadding(Constants.margin)
        textField.returnKeyType = .done
        textField.addTarget(self, action: #selector(textDidUpdate), for: .editingChanged)
        textField.delegate = self
        textField.autocapitalizationType = .words
        self.addSubview(textField)
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        textField.layer.borderColor = Colors.lightColor.cgColor
    }
    
    @discardableResult
    override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }
    
    @discardableResult
    override func resignFirstResponder() -> Bool {
        textField.resignFirstResponder()
    }
    
    @objc func textDidUpdate() {
        if !isValid {
            if textField.hasText {
                isValid = true
                delegate?.nameDidBecomeValid()
            }
        }
        else {
            if !textField.hasText {
                isValid = false
                delegate?.nameDidBecomeInvalid()
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let frame = bounds.insetBy(dx: margin, dy: 0)
        
        let titleSize = titleLabel.sizeThatFits(frame.size)
        let textFieldSize = CGSize(width: frame.width, height: 50)
        
        titleLabel.contextualFrame = CGRect(
            x: frame.midX - titleSize.width/2,
            y: frame.height * (frame.width < 343 ? 0.05 : 0.1),
            width: titleSize.width,
            height: titleSize.height)
        
        let textFieldY = frame.height * (frame.width < 343 ? 0.26 : 0.32)
        textField.contextualFrame = CGRect(
            x: frame.midX - textFieldSize.width/2,
            y: min(textFieldY, bounds.maxY - keyboardHeight - textFieldSize.height*2 - 24),
            width: textFieldSize.width,
            height: textFieldSize.height)
        
    }
}

class ProfileIconView: CancelTouchScrollView {
    
    private let titleLabel = UILabel()
    
    private let iconView = IconView()
    private let iconPicker = IconPickerView()
    
    public var action: ((String)->Void)?
    
    public var margin: CGFloat = 0
    
    public var initialIcon: String? {
        didSet {
            if let icon = initialIcon {
                iconPicker.selectedIcon = initialIcon
                self.iconView.icon = UIImage(named: icon)
            }
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        self.showsVerticalScrollIndicator = false
        
        let attStr = NSMutableAttributedString(string: "Choose an\n", font: Fonts.bold.withSize(38), color: Colors.text)
        attStr.append(NSAttributedString(string: "icon", font: Fonts.heavy.withSize(38), color: Colors.orange))
        titleLabel.attributedText = attStr
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        self.addSubview(titleLabel)
        
        iconView.backgroundColor = Colors.lightColor
        self.addSubview(iconView)
        
        iconPicker.selectionAction = {
            [weak self] iconName in
            guard let self = self else { return }
            self.iconView.icon = UIImage(named: iconName)
            self.action?(iconName)
        }
        self.addSubview(iconPicker)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let frame = self.bounds.insetBy(dx: margin, dy: 0)
        
        let titleSize = titleLabel.sizeThatFits(frame.size)
        
        titleLabel.frame = CGRect(
            x: frame.midX - titleSize.width/2,
            y: frame.height * (frame.width < 343 ? 0.04 : 0.08),
            width: titleSize.width,
            height: titleSize.height)
        
        let iconBGSize = frame.width * 0.55
        iconView.frame = CGRect(
            x: frame.midX - iconBGSize/2,
            y: titleLabel.frame.maxY + 24,
            width: iconBGSize,
            height: iconBGSize)
        
        iconView.iconInsets = UIEdgeInsets(floor(iconBGSize*0.16))
        iconView.roundCorners(prefersContinuous: false)
             
        
        let height = iconPicker.sizeThatFits(frame.size).height
        iconPicker.frame = CGRect(
            x: frame.minX, y: iconView.frame.maxY + 32,
            width: frame.width, height: height)
        
        self.contentSize.height = iconPicker.frame.maxY
        self.contentInset.bottom = 16
                
        
    }
}

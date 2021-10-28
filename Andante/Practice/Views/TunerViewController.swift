//
//  TunerViewController.swift
//  Andante
//
//  Created by Miles Vinson on 11/17/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//
import UIKit

class TunerViewController: PickerAlertController {
    
    private let optionsControl = TunerTypeControl()
    private let octavePicker = OctavePicker()
    
    private var noteButtons: [PushButton] = []
    private var volumeSlider = UISlider()
    
    private var note: Int?
    
    private let tuner = Tuner()

    private var selectedOption = 0
    
    public var isPlaying: Bool {
        return tuner.isPlaying
    }
    
    public func stop() {
        tuner.stop()
    }
    
    public func start() {
        tuner.play()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.contentWidth = 375
        
        contentView.addSubview(octavePicker)
        contentView.addSubview(optionsControl)
        
        for i in 0...11 {
            let button = PushButton()
            button.transformScale = 0.96
            button.tag = i
            button.action = {
                [weak self] in
                guard let self = self else { return }
                self.didSelectNote(i)
            }
            
            deselectButton(button)
            
            contentView.addSubview(button)
            noteButtons.append(button)
        }
        
        volumeSlider.minimumValue = 0
        volumeSlider.maximumValue = 1
        volumeSlider.value = 1
        volumeSlider.minimumValueImage = UIImage(name: "speaker.fill", pointSize: 12, weight: .medium)
        volumeSlider.maximumValueImage = UIImage(name: "speaker.3.fill", pointSize: 12, weight: .medium)
        volumeSlider.tintColor = Colors.extraLightText
        volumeSlider.minimumTrackTintColor = Colors.extraLightText
        volumeSlider.maximumTrackTintColor = Colors.lightColor
        volumeSlider.addTarget(self, action: #selector(sliderDidChange), for: .valueChanged)
        contentView.addSubview(volumeSlider)
        
        optionsControl.action = {
            [weak self] option in
            guard let self = self else { return }
            
            self.selectedOption = option
            self.animate(option)
            self.tuner.setSelectedTuner(option)
        }
        
        octavePicker.changeHandler = {
            [weak self] octave in
            guard let self = self else { return }
            
            self.tuner.octave = octave
        }
        
    }
    
    private func animate(_ option: Int) {
        
        if option == 1 {
            UIView.animate(withDuration: 0.14  ) {
                self.octavePicker.alpha = 0
                self.octavePicker.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }
        } else {
            UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .curveEaseOut) {
                self.octavePicker.alpha = 1
                self.octavePicker.transform = .identity
            } completion: { (complete) in }
        }
        
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.viewDidLayoutSubviews()
        } completion: { (complete) in }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        tuner.stop()
    }
    
    @objc func sliderDidChange() {
        tuner.volume = volumeSlider.value
    }
    
    func didSelectNote(_ note: Int) {
        
        if note == self.note {
            self.note = nil
            tuner.stop()
        } else {
            let shouldPlay = self.note == nil
            self.note = note
            
            tuner.setNote(note)
            if shouldPlay {
                tuner.play()
            }
        }
        
        for button in noteButtons {
            if button.tag == self.note {
                selectButton(button)
            } else {
                deselectButton(button)
            }
        }
        
        UIView.transition(with: self.volumeSlider, duration: 0.15, options: [.transitionCrossDissolve]) {
            if self.note == nil {
                self.volumeSlider.minimumTrackTintColor = Colors.extraLightText
            } else {
                self.volumeSlider.minimumTrackTintColor = Colors.orange
            }
        } completion: { (complete) in }

    }
    
    override func viewDidLayoutSubviews() {
        
        let octaveHeight: CGFloat = 54
        let buttonsHeight: CGFloat = 260
        let spacing: CGFloat = 24 + 20
        let volumeHeight: CGFloat = 60
        let optionsHeight: CGFloat = 58
        let bottomSpace: CGFloat = max(view.safeAreaInsets.bottom - 6, 16)
        
        if selectedOption == 0 {
            contentHeight =
                buttonsHeight
                + spacing
                + volumeHeight
                + optionsHeight
                + octaveHeight
                + bottomSpace
                + Constants.margin
        } else {
            contentHeight =
                buttonsHeight
                + spacing
                + volumeHeight
                + optionsHeight
                + bottomSpace
                + Constants.margin
        }
        
        super.viewDidLayoutSubviews()

        let buttonsFrame = CGRect(
            x: Constants.margin,
            y: Constants.margin,
            width: self.contentView.bounds.width - Constants.margin*2,
            height: buttonsHeight)
        
        let buttonSpacing: CGFloat = 3
        let buttonWidth: CGFloat = (buttonsFrame.width - buttonSpacing*2)/3
        let buttonHeight: CGFloat = (buttonsFrame.height - buttonSpacing*3)/4
        
        for (i, button) in noteButtons.enumerated() {
            
            let col = CGFloat(i / 3)
            let row = CGFloat(i % 3)
            
            button.frame = CGRect(
                x: buttonsFrame.minX + row*(buttonWidth + buttonSpacing),
                y: buttonsFrame.minY + col*(buttonHeight + buttonSpacing),
                width: buttonWidth,
                height: buttonHeight)
            
            if col == 3 && row == 0 {
                button.cornerRadius = 8
                button.buttonView.layer.maskedCorners = [.layerMinXMaxYCorner]
            } else if col == 3 && row == 2 {
                button.cornerRadius = 8
                button.buttonView.layer.maskedCorners = [.layerMaxXMaxYCorner]
            } else if col == 0 && row == 0 {
                button.cornerRadius = 8
                button.buttonView.layer.maskedCorners = [.layerMinXMinYCorner]
            } else if col == 0 && row == 2 {
                button.cornerRadius = 8
                button.buttonView.layer.maskedCorners = [.layerMaxXMinYCorner]
            }
        }
        
        
        octavePicker.contextualFrame = CGRect(
            x: 0, y: selectedOption == 0 ? buttonsFrame.maxY + 4 : buttonsFrame.maxY + 4 - 30, width: contentView.bounds.width, height: 50)
        
        volumeSlider.frame = CGRect(
            x: Constants.margin,
            y: selectedOption == 0 ? buttonsFrame.maxY + 24 + octaveHeight : buttonsFrame.maxY + 24 ,
            width: contentView.bounds.width - Constants.margin*2,
            height: 60)
        
        optionsControl.frame = CGRect(
            x: Constants.smallMargin, y: volumeSlider.frame.maxY + 20,
            width: contentView.bounds.width - Constants.smallMargin*2,
            height: 58)
        
    }
    
    func selectButton(_ button: PushButton) {
        UIView.animate(withDuration: 0.1) {
            button.backgroundColor = Colors.orange
        }
        button.setTitle(string(for: button.tag), color: Colors.white, font: Fonts.medium.withSize(19))
    }
    
    func deselectButton(_ button: PushButton) {
        button.backgroundColor = Colors.lightColor
        button.setTitle(string(for: button.tag), color: Colors.text, font: Fonts.regular.withSize(19))
    }
    
    func string(for note: Int) -> String {
        switch note {
        case 0: return "C"
        case 1: return " D♭"
        case 2: return "D"
        case 3: return " E♭"
        case 4: return "E"
        case 5: return "F"
        case 6: return " F♯"
        case 7: return "G"
        case 8: return " A♭"
        case 9: return "A"
        case 10: return " B♭"
        case 11: return "B"
        default: return ""
        }
    }
    
}

private class TunerTypeControl: UIView {
    
    let option1 = UIButton(type: .system)
    let option2 = UIButton(type: .system)
    let selectionView = UIView()
    
    public var action: ((_: Int)->Void)?
    
    public var option = 0
    
    init() {
        super.init(frame: .zero)
        
        selectionView.backgroundColor = Colors.orange
        selectionView.setShadow(radius: 6, yOffset: 3, opacity: 0.01, color: Colors.orange)
        addSubview(selectionView)
        
        option1.setTitle("Pure", color: Colors.white, font: Fonts.semibold.withSize(16))
        option1.isUserInteractionEnabled = false
        option1.addTarget(self, action: #selector(didTapOption1), for: .touchUpInside)
        addSubview(option1)
        
        option2.setTitle("Strings", color: Colors.text.withAlphaComponent(0.85), font: Fonts.medium.withSize(16))
        option2.addTarget(self, action: #selector(didTapOption2), for: .touchUpInside)
        addSubview(option2)
        
        self.backgroundColor = Colors.lightColor
        
    }
    
    @objc func didTapOption1() {
        setOption(0)
    }
    
    @objc func didTapOption2() {
        setOption(1)
    }
    
    func setOption(_ option: Int) {
        self.option = option
        action?(option)
        
        let selectedOption = option == 0 ? option1 : option2
        let unselectedOption = option == 0 ? option2 : option1
        
        selectedOption.setTitleColor(Colors.white, for: .normal)
        selectedOption.titleLabel?.font = Fonts.semibold.withSize(16)
        selectedOption.isUserInteractionEnabled = false
        
        unselectedOption.setTitleColor(Colors.text.withAlphaComponent(0.85), for: .normal)
        unselectedOption.titleLabel?.font = Fonts.medium.withSize(16)
        unselectedOption.isUserInteractionEnabled = true
        
        UIView.animateWithCurve(
            duration: 0.5,
            x1: 0.16, y1: 1, x2: 0.3, y2: 1,
            animation: {
                self.layoutSelectionView()
            }, completion: nil)
       
    }
    
    func layoutSelectionView() {
        let insetFrame = bounds.insetBy(dx: 3, dy: 3)
        selectionView.frame = CGRect(
            x: option == 0 ? insetFrame.minX : insetFrame.midX, y: insetFrame.minY,
            width: insetFrame.width/2, height: insetFrame.height)
        selectionView.roundCorners()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutSelectionView()
        
        option1.frame = CGRect(
            x: 0, y: 0, width: bounds.width/2, height: bounds.height)
        
        option2.frame = CGRect(
            x: bounds.midX, y: 0, width: bounds.width/2, height: bounds.height)
        
        self.roundCorners()
        
    }
}

fileprivate class OctavePicker: UIView {
    
    private let label = UILabel()
    
    private let bgView = UIView()
    private let selectedView = UIView()
    private var buttons: [UIButton] = []
    private let feedback = UIImpactFeedbackGenerator(style: .light)
    private var value = 1
    
    public var changeHandler: ((Int)->Void)?
    
    init() {
        super.init(frame: .zero)
        
        label.text = "Octave"
        label.font = Fonts.regular.withSize(16)
        label.textColor = Colors.lightText
        addSubview(label)
        
        bgView.backgroundColor = Colors.lightColor
        bgView.roundCorners(7)
        self.addSubview(bgView)
        
        selectedView.backgroundColor = Colors.dynamicColor(
            light: Colors.foregroundColor,
            dark: Colors.text.withAlphaComponent(0.25))
        selectedView.setShadow(radius: 4, yOffset: 1, opacity: 0.08)
        selectedView.roundCorners(6)
        self.addSubview(selectedView)
        
        feedback.prepare()
        
        for i in 0...3 {
            let button = PushButton()
            button.tag = i
            button.setTitle("\(i+3)", color: Colors.text, font: Fonts.medium.withSize(16))
            
            button.action = {
                [weak self] in
                guard let self = self else { return }
                self.didSelectButton(button)
                self.feedback.impactOccurred()
            }
            
            if i == 1 {
                button.isUserInteractionEnabled = false
                button.alpha = 1
                button.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }
            else {
                button.isUserInteractionEnabled = true
                button.alpha = 0.8
                button.transform = .identity
            }
            
            self.addSubview(button)
            buttons.append(button)
        }
        
        
        
    }
    
    @objc func didSelectButton(_ sender: UIButton) {
        
        self.value = sender.tag
        
        self.changeHandler?(value+2)
        
        for button in buttons {
            UIView.animate(withDuration: 0.18) {
                if button.tag == sender.tag {
                    button.isUserInteractionEnabled = false
                    button.alpha = 1
                    button.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                }
                else {
                    button.isUserInteractionEnabled = true
                    button.alpha = 0.8
                    button.transform = .identity
                }
            }
        }
        
        UIView.animate(withDuration: 0.26, delay: 0, usingSpringWithDamping: 0.88, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            self.layoutSubviews()
        }, completion: nil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.sizeToFit()
        label.frame.origin = CGPoint(
            x: Constants.margin, y: 22)
        
        let totalWidth: CGFloat = 160
        
        bgView.frame = CGRect(
            x: self.bounds.maxX - Constants.margin - totalWidth,
            y: label.center.y - 20,
            width: totalWidth, height: 40).insetBy(dx: -2, dy: 0)
        
        let width = (bgView.bounds.width - 4)/4
        
        for i in 0..<buttons.count {
            
            let button = buttons[i]
            let frame = CGRect(
                x: bgView.frame.minX + 2 + CGFloat(i)*width,
                y: bgView.frame.minY, width: width, height: bgView.bounds.height)
            button.bounds.size = frame.size
            button.center = frame.center
            
        }
        
        let selectedValue = value
        selectedView.frame = CGRect(
            x: bgView.frame.minX + CGFloat(selectedValue)*width + 4,
            y: bgView.frame.minY + 4,
            width: width - 4,
            height: bgView.bounds.height - 8)
        
    }
    
}

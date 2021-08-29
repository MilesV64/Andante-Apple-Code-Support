//
//  MetronomeToolView.swift
//  Andante
//
//  Created by Miles Vinson on 7/26/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit
import AVFoundation

protocol MetronomeToolViewDelegate: class {
    func metronomeDidTick()
}

class MetronomeToolView: PracticeToolView, MetronomeDelegate {
    
    var metronome = Metronome()
    
    public weak var delegate: MetronomeToolViewDelegate?
    
    private let label = UILabel()
    private let bpmLabel = UILabel()
    
    private var bpm: Int = 0
    private var bpmInterval: CFTimeInterval = 0
    
    private let slider = UISlider()
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    private var timer: Timer?
    private var lastTick: CFAbsoluteTime?
    
    private let stepper = Stepper()
    
    override init() {
        super.init()
        
        metronome.delegate = self
        
        setBPM(80)
        
        label.textColor = PracticeColors.text
        label.font = Fonts.regular.withSize(18)
        contentView.addSubview(label)
        
        bpmLabel.textColor = PracticeColors.lightText
        bpmLabel.font = Fonts.semibold.withSize(13)
        bpmLabel.text = "BPM"
        contentView.addSubview(bpmLabel)
        
        slider.minimumTrackTintColor = PracticeColors.lightFill
        slider.maximumTrackTintColor = PracticeColors.lightFill
        slider.thumbTintColor = PracticeColors.purple
        slider.addTarget(self, action: #selector(sliderDidChange), for: .valueChanged)
        slider.minimumValue = 20
        slider.maximumValue = 100
        slider.value = Float(self.bpm/2)
        contentView.addSubview(slider)
        
        stepper.value = self.bpm
        stepper.minValue = 40
        stepper.maxValue = 200
        stepper.action = {
            [weak self] value in
            guard let self = self else { return }
            self.setBPM(value)
            self.slider.value = Float(self.bpm/2)
        }
        contentView.addSubview(stepper)
        
    }
    
    override func show(delay: TimeInterval = 0) {
        super.show(delay: delay)
        //self.start()
        
        metronome.setTempo(to: bpm)
        try? metronome.start()
    }
    
    override func hide(delay: TimeInterval = 0) {
        super.hide(delay: delay)
        //self.stop()
        
        metronome.stop()
    }
    
    private func start() {
        lastTick = nil
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true, block: {
            [weak self] _ in
            guard let self = self else { return }
            self.timerDidFire()
        })
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func stop() {
        timer?.invalidate()
        timer = nil
        lastTick = nil
    }
    
    func metronomeTicking(_ metronome: Metronome, currentTick: Int) {
        delegate?.metronomeDidTick()
    }
    
    private var count: Double = 0
    private var avg: CFAbsoluteTime = 0
    private func timerDidFire() {
        if let lastTick = self.lastTick {
            let time = CFAbsoluteTimeGetCurrent()
            
            let elapsedTime = time - lastTick
            if (abs(elapsedTime - bpmInterval) < 0.008) || (elapsedTime >= bpmInterval) {
                delegate?.metronomeDidTick()
                self.lastTick? += bpmInterval
                
                let newVal = abs(elapsedTime - bpmInterval)
                avg = (avg*count + newVal) / (count + 1)
                count += 1
                print(count, avg - bpmInterval)
            }
            
        }
        else {
            // subtract some time to make it start sooner
            lastTick = CFAbsoluteTimeGetCurrent()
        }
    }
    
    @objc func sliderDidChange() {
        let bpm = Int(slider.value)*2
        if bpm != self.bpm {
            setBPM(bpm)
            stepper.value = bpm
        }
        
    }
    
    private func setBPM(_ value: Int) {
        self.bpm = value
        self.bpmInterval = 60/Double(bpm)
        avg = 0
        count = 0
        metronome.setTempo(to: value)
        setLabelText()
    }
    
    private func setLabelText() {
        label.text = "\(bpm)"
        layoutLabels()
    }
    
    private func layoutLabels() {
        label.frame = CGRect(
            x: Constants.smallMargin,
            y: self.bounds.midY - 10, width: 70, height: 20)
        
        bpmLabel.sizeToFit()
        var spacing: CGFloat
        if bpm == 200 {
            spacing = 36
        }
        else if bpm > 99 {
            spacing = 34
        }
        else {
            spacing = 26
        }
        bpmLabel.frame.origin = CGPoint(
            x: label.frame.minX + spacing, y: label.frame.midY - 6)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setLabelText()
        
        stepper.sizeToFit()
        stepper.frame.origin = CGPoint(
            x: contentView.bounds.maxX - Constants.smallMargin - stepper.bounds.width + CGFloat(10),
            y: contentView.bounds.midY - stepper.bounds.height/2)
        
        
        slider.frame = CGRect(
            from: CGPoint(x: label.frame.maxX + 1, y: 0),
            to: CGPoint(x: stepper.frame.minX, y: contentView.bounds.maxY))
        
        
    }
}


class Stepper: UIView {
    
    private let bgView = UIView()
    private let separator = UIView()
    
    private let minusButton = CustomButton()
    private let plusButton = CustomButton()
    
    private let minusGesture = UILongPressGestureRecognizer()
    private let plusGesture = UILongPressGestureRecognizer()
    
    private let feedback = UIImpactFeedbackGenerator(style: .light)
    
    public var value: Int = 0 {
        didSet {
            setButtonStates()
        }
    }
    
    public var minValue: Int = 0 {
        didSet {
            setButtonStates()
        }
    }
    
    public var maxValue: Int = 1 {
        didSet {
            setButtonStates()
        }
    }
    
    public var action: ((Int)->Void)?
    
    init() {
        super.init(frame: .zero)
        
        bgView.backgroundColor = PracticeColors.lightFill
        self.addSubview(bgView)
        
        minusButton.touchMargin = 0
        minusButton.contentEdgeInsets.left = 10
        minusButton.setImage(UIImage(name: "minus", pointSize: 14, weight: .medium), for: .normal)
        minusButton.tintColor = PracticeColors.text
        minusButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.didTapMinus()
        }
        minusGesture.minimumPressDuration = 0.3
        minusButton.addGestureRecognizer(minusGesture)
        minusGesture.addTarget(self, action: #selector(handleLongPress(_:)))
        self.addSubview(minusButton)
        
        plusButton.touchMargin = 0
        plusButton.contentEdgeInsets.right = 10
        plusButton.setImage(UIImage(name: "plus", pointSize: 14, weight: .medium), for: .normal)
        plusButton.tintColor = PracticeColors.text
        plusButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.didTapPlus()
        }
        plusGesture.minimumPressDuration = 0.3
        plusButton.addGestureRecognizer(plusGesture)
        plusGesture.addTarget(self, action: #selector(handleLongPress(_:)))
        self.addSubview(plusButton)
        
        separator.backgroundColor = PracticeColors.lightText.withAlphaComponent(0.12)
        separator.isUserInteractionEnabled = false
        self.addSubview(separator)
    }
    
    private func didTapMinus() {
        feedback.impactOccurred()
        value = max(minValue, value - 1)
        action?(value)
    }
    
    private func didTapPlus() {
        feedback.impactOccurred()
        value = min(maxValue, value + 1)
        action?(value)
    }
    
    private func setButtonStates() {
        minusButton.isEnabled = value > minValue
        plusButton.isEnabled = value < maxValue
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            feedback.impactOccurred()
            startGestureIncrement(gesture === plusGesture ? 1 : -1)
        }
        else if gesture.state == .cancelled || gesture.state == .ended {
            endGestureIncrement(gesture === plusGesture ? 1 : -1)
        }
    }
    
    private var gestureTimer: Timer?
    private var lastUpdate: CFTimeInterval = 0
    private var startTime: CFTimeInterval = 0
    private func startGestureIncrement(_ direction: Int) {
        self.lastUpdate = CACurrentMediaTime()
        self.startTime = lastUpdate
        let button = direction == 1 ? plusButton : minusButton
        gestureTimer = Timer.scheduledTimer(withTimeInterval: 0.008, repeats: true, block: {
            [weak self] timer in
            guard let self = self else { return }
            button.isHighlighted = true
            let rampupTime: CFTimeInterval = 0.7
            let startInterval: CFTimeInterval = 0.1
            let endInterval: CFTimeInterval = 0.01
            let diff: CFTimeInterval = startInterval - endInterval
            let progress = max(0, min(1, (CACurrentMediaTime() - self.startTime) / rampupTime))
            let interval = startInterval - diff*progress
            
            if CACurrentMediaTime() > self.lastUpdate + interval {
                self.lastUpdate = CACurrentMediaTime()
                self.value = min(self.maxValue, max(self.minValue, self.value + direction))
                self.action?(self.value)
            }
            
        })
    }
    
    private func endGestureIncrement(_ direction: Int) {
        gestureTimer?.invalidate()
        gestureTimer = nil
        let button = direction == 1 ? plusButton : minusButton
        button.isHighlighted = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: 84, height: 52)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let inset: CGFloat = 10
        bgView.frame = self.bounds.insetBy(dx: inset, dy: inset)
        bgView.roundCorners(5)
        
        minusButton.frame = CGRect(
            x: 0, y: 0,
            width: self.bounds.width/2,
            height: self.bounds.height)
        
        plusButton.frame = CGRect(
            x: self.bounds.midX, y: 0,
            width: self.bounds.width/2,
            height: self.bounds.height)
        
        let separatorWidth: CGFloat = 1/UIScreen.main.scale
        separator.bounds.size = CGSize(width: separatorWidth, height: bgView.bounds.height - 12)
        separator.center = self.bounds.center
        
    }
}

//
//  RecordingButton.swift
//  Andante
//
//  Created by Miles Vinson on 4/19/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

protocol RecordingButtonDelegate: class {
    func recordingButtonDidTapStart()
    func recordingButtonDidTapStop()
}

class RecordingButton: UIView {
    
    public weak var delegate: RecordingButtonDelegate?
        
    private let startButton = PushButton()
    
    private let stopButton = PushButton()
    private let stopContent = UIView()
    
    private var buttonsView = UIView()
    
    enum State {
        case start, stop
    }
    
    private var state: State = .start
    
    private var highlightedTransform = CGAffineTransform(scaleX: 0.88, y: 0.88)
    private var regularTransform = CGAffineTransform(scaleX: 0.95, y: 0.95)
    private var selectedTransform = CGAffineTransform.identity
    
    init() {
        super.init(frame: .zero)
        
        startButton.buttonView.layer.borderColor = UIColor.clear.cgColor
        startButton.buttonView.layer.borderWidth = 2
        
        startButton.buttonView.backgroundColor = PracticeColors.unselectedToolButtonBG
        startButton.buttonView.setImage(UIImage(name: "mic", pointSize: 18, weight: .regular), for: .normal)
        startButton.buttonView.tintColor = Colors.dynamicColor(light: Colors.white, dark: PracticeColors.text)
        
        stopButton.alpha = 0
        stopButton.isUserInteractionEnabled = false
        stopContent.backgroundColor = Colors.red
        stopButton.transformScale = 0.86
        stopButton.addSubview(stopContent)
        
        startButton.action = { [weak self] in
            self?.stopButton.isUserInteractionEnabled = false
            self?.startButton.isUserInteractionEnabled = false
            self?.delegate?.recordingButtonDidTapStart()
        }
        
        stopButton.action = { [weak self] in
            self?.stopButton.isUserInteractionEnabled = false
            self?.startButton.isUserInteractionEnabled = true
            self?.delegate?.recordingButtonDidTapStop()
        }
        
        buttonsView.backgroundColor = .clear
        buttonsView.addSubview(startButton)
        buttonsView.addSubview(stopButton)
        buttonsView.transform = regularTransform
        self.addSubview(buttonsView)
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if startButton.buttonView.layer.borderColor != UIColor.clear.cgColor {
            startButton.buttonView.layer.borderColor = PracticeColors.text.cgColor
        }
    }
    
    public func setState(_ state: RecordingButton.State) {
        self.state = state
        
        if state == .start {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.startButton.buttonView.backgroundColor = PracticeColors.unselectedToolButtonBG
                self.startButton.buttonView.tintColor = Colors.dynamicColor(light: Colors.white, dark: PracticeColors.text)
                self.stopButton.alpha = 0
                self.stopButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                self.buttonsView.transform = self.regularTransform
            }) { (complete) in
                self.stopButton.isUserInteractionEnabled = false
                self.startButton.isUserInteractionEnabled = true
            }
            animateBorderColor(to: .clear, duration: 0.15)
        }
        else {
            self.stopButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            self.stopButton.alpha = 0
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.startButton.buttonView.backgroundColor = .clear
                self.startButton.buttonView.tintColor = .clear
                self.stopButton.transform = .identity
                self.stopButton.alpha = 1
                self.buttonsView.transform = self.selectedTransform
            }, completion: { complete in
                self.stopButton.isUserInteractionEnabled = true
                self.startButton.isUserInteractionEnabled = false
            })
            animateBorderColor(to: PracticeColors.text, duration: 0.3)
        }
    }
    
    private func animateBorderColor(to: UIColor, duration: Double) {
        
        let anim = CABasicAnimation(keyPath: "borderColor")
        anim.fromValue = startButton.buttonView.layer.borderColor
        anim.toValue = to.cgColor
        anim.duration = duration
        startButton.buttonView.layer.add(anim, forKey: "borderColor")
        startButton.buttonView.layer.borderColor = to.cgColor
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        buttonsView.center = self.bounds.center
        buttonsView.bounds.size = self.bounds.size
        
        stopButton.center = buttonsView.bounds.center
        stopButton.bounds.size = buttonsView.bounds.size
        stopContent.frame = CGRect(center: stopButton.bounds.center, size: CGSize(18))
        stopContent.maskCorners(5)
        
        startButton.center = buttonsView.bounds.center
        startButton.bounds.size = buttonsView.bounds.size
        startButton.buttonView.roundCorners(prefersContinuous: false)
        
        
    }
    
}

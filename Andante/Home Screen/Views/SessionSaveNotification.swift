//
//  SessionSaveNotification.swift
//  Andante
//
//  Created by Miles Vinson on 7/22/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit
import CoreData

class SessionSaveNotification: PushButton {
    
    private let progressCircle = ConfettiCircle()
    private let label = UILabel()
    private let arrow = UIImageView()
    
    override init() {
        super.init()
        
        self.backgroundColor = Colors.orange
        self.cornerRadius = 14
        self.setShadow(radius: 12, yOffset: 4, opacity: 0.24)
        
        self.addSubview(progressCircle)
        
        label.text = "Session saved!"
        label.font = Fonts.regular.withSize(17)
        label.textColor = Colors.white
        self.addSubview(label)
        
        arrow.image = UIImage(name: "chevron.right", pointSize: 14, weight: .semibold)
        arrow.setImageColor(color: Colors.white.withAlphaComponent(0.8))
        self.addSubview(arrow)
    }
    
    public func trigger(_ session: CDSession) {
        
        guard
            let profile = session.profile,
            let attributes = session.attributes,
            let date = attributes.startTime
        else {
            return
        }
        
        //Can't rely on practice database updating in time for this to trigger
        var sessions = PracticeDatabase.shared.sessions(for: Day(date: date)) ?? []

        if !sessions.contains(attributes) {
            sessions.append(attributes)
        }
        
        progressCircle.label.text = String(Formatter.weekdayString(session.startTime).prefix(1))
        
        let practiceTime = sessions.reduce(into: Int(0)) { $0 += Int($1.practiceTime) }
        
        let initialTime = CGFloat(practiceTime - session.practiceTime) / CGFloat(profile.dailyGoal)
        let finalTime = CGFloat(practiceTime) / CGFloat(profile.dailyGoal)
        
        self.progressCircle.setInitialProgress(initialTime)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.progressCircle.setProgress(finalTime)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        progressCircle.frame = CGRect(
            x: Constants.margin,
            y: self.bounds.midY - 18,
            width: 36,
            height: 36)
        
        label.sizeToFit()
        label.frame.origin = CGPoint(
            x: progressCircle.frame.maxX + 12,
            y: self.bounds.midY - label.bounds.height/2)
        
        arrow.sizeToFit()
        arrow.frame.origin = CGPoint(
            x: self.bounds.maxX - 26,
            y: self.bounds.midY - arrow.bounds.height/2)
        
    }
}

fileprivate class ConfettiCircle: UIView, AnimatorDelegate {
    
    private let feedback = UIImpactFeedbackGenerator(style: .medium)
    
    public let label = UILabel()
    private let arcView = UIView()
    private let fgArc = CAShapeLayer()
    private let bgArc = CAShapeLayer()
    private let animator = Animator()
    
    private var progress: CGFloat = 0
    private var didConfetti = false
    private var shouldConfetti = false
    
    init() {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        
        arcView.backgroundColor = .clear
        self.addSubview(arcView)
        
        bgArc.strokeColor = Colors.white.withAlphaComponent(0.12).cgColor
        bgArc.lineWidth = 4
        bgArc.lineCap = .round
        bgArc.fillColor = UIColor.clear.cgColor
        arcView.layer.addSublayer(bgArc)
        
        fgArc.strokeColor = Colors.white.cgColor
        fgArc.lineWidth = 4
        fgArc.lineCap = .round
        fgArc.fillColor = UIColor.clear.cgColor
        arcView.layer.addSublayer(fgArc)
        
        label.text = "W"
        label.textColor = Colors.white.withAlphaComponent(0.9)
        label.textAlignment = .center
        label.font = Fonts.semibold.withSize(13)
        self.addSubview(label)
        
        animator.delegate = self
    }
    
    func setInitialProgress(_ progress: CGFloat) {
        self.progress = min(1, progress)
    }
    
    func setProgress(_ progress: CGFloat) {
        
        shouldConfetti = self.progress < 1 && progress >= 1
        
        animator.startValue = self.progress
        animator.endValue = min(1, progress)
        animator.startAnimation(duration: 1.8, easing: Curve.exponential.easeInOut)
        self.progress = min(1, progress)
        
        if shouldConfetti {
            feedback.prepare()
        }
    }
    
    func animationDidUpdate(phase: CGFloat) {
        let start = animator.startValue as! CGFloat
        let end = animator.endValue as! CGFloat
        
        let progress = start + (end - start) * phase
        
        let path = UIBezierPath()
        path.addArc(
            withCenter: self.bounds.center,
            radius: self.bounds.width/2 - 2,
            startAngle: -CGFloat.pi/2, endAngle: -CGFloat.pi/2 + (progress * CGFloat.pi*2),
            clockwise: true)
        
        fgArc.path = path.cgPath
        
        if shouldConfetti && !didConfetti && progress > 0.96 {
            didConfetti = true
            
            confetti()
        }
        
    }
    
    private func confetti() {
        feedback.impactOccurred()
        
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn, animations: {
            self.arcView.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        }) { (complete) in
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                self.arcView.transform = .identity
            }, completion: nil)
        }
        
        
        animateConfetti()
        
    }
    
    private func animateConfetti() {
        
        let colors: [UIColor] = [
            Colors.sessionsColor,
            Colors.lightBlue,
            Colors.red,
            Colors.green,
            UIColor("#FC25EB"),
            Colors.white,
            Colors.white,
            Colors.white
        ]
        
        func makeView() -> UIView {
            let view = UIView()
            view.backgroundColor = colors[Int.random(in: 0..<colors.count)]
            view.bounds.size = CGSize(3)
            view.center = self.bounds.center
            view.layer.cornerRadius = 1.5
            self.addSubview(view)
            return view
        }
        
        func getTransform(angle: CGFloat, radius: CGFloat) -> CGAffineTransform {
            return CGAffineTransform(translationX: cos(angle)*radius, y: sin(angle)*radius)
        }
        
        let startAngle = -CGFloat.pi/2
        let angleStep = (2*CGFloat.pi)/7
        let angleOffset = CGFloat.pi/6
        for i in 0..<7 {
            
            let leftView = makeView()
            let rightView = makeView()
            
            let angle = startAngle + angleStep*CGFloat(i)
            
            leftView.transform = getTransform(angle: angle - angleOffset, radius: self.bounds.width/2)
            rightView.transform = getTransform(angle: angle + angleOffset, radius: self.bounds.width/2)
            
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveLinear, animations: {
                rightView.transform = getTransform(angle: angle + angleOffset, radius: self.bounds.width*0.6)
            }) { (complete) in
                UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut, animations: {
                    rightView.transform = getTransform(angle: angle + angleOffset, radius: self.bounds.width*6.2).concatenating(CGAffineTransform(scaleX: 0.1, y: 0.1))
                    rightView.alpha = 0
                }, completion: nil)
            }
            
            UIView.animate(withDuration: 0.35, delay: 0, options: .curveLinear, animations: {
                leftView.transform = getTransform(angle: angle - angleOffset, radius: self.bounds.width*0.75)
            }) { (complete) in
                UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut, animations: {
                    leftView.transform = getTransform(angle: angle - angleOffset, radius: self.bounds.width*7.7).concatenating(CGAffineTransform(scaleX: 0.1, y: 0.1))
                    leftView.alpha = 0
                }, completion: nil)
            }
            
        }
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        bgArc.strokeColor = Colors.white.withAlphaComponent(0.12).cgColor
        fgArc.strokeColor = Colors.white.cgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        arcView.bounds.size = self.bounds.size
        arcView.center = self.bounds.center
        
        label.frame = self.bounds
        bgArc.frame = self.bounds
        fgArc.frame = self.bounds
        
        let path = UIBezierPath()
        path.addArc(
            withCenter: self.bounds.center,
            radius: self.bounds.width/2 - 2,
            startAngle: -CGFloat.pi/2, endAngle: -CGFloat.pi/2 + CGFloat.pi*2,
            clockwise: true)
        
        bgArc.path = path.cgPath
        
        path.addArc(
            withCenter: self.bounds.center,
            radius: self.bounds.width/2 - 2,
            startAngle: -CGFloat.pi/2, endAngle: -CGFloat.pi/2 + (self.progress * CGFloat.pi*2),
            clockwise: true)
        
        fgArc.path = UIBezierPath(
            arcCenter: self.bounds.center,
            radius: self.bounds.width/2 - 2,
            startAngle: -CGFloat.pi/2, endAngle: -CGFloat.pi/2 + (self.progress * CGFloat.pi*2),
            clockwise: true).cgPath
        
    }
}

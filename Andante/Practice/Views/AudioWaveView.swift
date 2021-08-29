//
//  AudioWaveView.swift
//  Andante
//
//  Created by Miles Vinson on 7/30/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class AudioWaveView: UIView {
    
    public var currentLoudness: CGFloat = 0
    
    private var samples: [UIView] = []
    
    /**
     Displaylink cycles
     */
    private let sampleRate = 3
    
    /**
     Displaylink cycle, resets every sampleRate
     */
    private var currentCycle = 0
    
    private var sampleRect: CGRect = .zero
    private var totalSamples: CGFloat = 50
    
    private var displayLink: CADisplayLink?
    private var currentIndex = 0
    
    private var contentView = UIView()
    private var currentOffset: CGFloat = 0
    private var offsetPerCycle: CGFloat = 0
    
    private let gradient = CAGradientLayer()
    
    
    init() {
        super.init(frame: .zero)

        self.addSubview(contentView)
        contentView.clipsToBounds = false
        
        gradient.colors = [
            PracticeColors.secondaryBackground.cgColor,
            PracticeColors.secondaryBackground.withAlphaComponent(0).cgColor]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        self.layer.addSublayer(gradient)
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        gradient.colors = [
            PracticeColors.secondaryBackground.cgColor,
            PracticeColors.secondaryBackground.withAlphaComponent(0).cgColor]
        
    }
    
    public func clearData() {
        currentCycle = 0
        currentOffset = 0
        currentIndex = 0
        contentView.transform = .identity
        for sample in self.samples {
            sample.removeFromSuperview()
        }
        samples.removeAll()
    }
    
    public func start() {
        displayLink?.invalidate()
        
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .current, forMode: .common)
    }
    
    public func pause() {
        displayLink?.invalidate()
    }
    
    @objc private func update() {
        
        currentCycle += 1
        
        if currentCycle >= sampleRate {
            currentCycle = 0
            addSample()
            if samples.count > Int(totalSamples) {
                removeFirstSample()
            }
        }
        
        if samples.count == Int(totalSamples) {
            currentOffset += offsetPerCycle
            contentView.transform = CGAffineTransform(translationX: -currentOffset, y: 0)
        }
        
    }
    
    private func addSample() {
        let sample = UIView()
        sample.backgroundColor = PracticeColors.text
                
        let center = CGPoint(x: CGFloat(currentIndex)*sampleRect.width + sampleRect.midX, y: sampleRect.midY)
        
        let height: CGFloat = max(4, (currentLoudness/100)*sampleRect.height)
        sample.bounds.size = CGSize(width: 4, height: 4)
        sample.center = center
        sample.layer.cornerRadius = 2
        sample.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        sample.alpha = 0
        
        UIView.animate(withDuration: 0.2) {
            sample.bounds.size = CGSize(width: 4, height: height)
            sample.center = center
            sample.transform = .identity
            sample.alpha = 1
        }
        
        contentView.addSubview(sample)
        samples.append(sample)
        currentIndex += 1
    }
    
    private func removeFirstSample() {
        let sample = samples.removeFirst()
        UIView.animate(withDuration: 0.2, animations: {
            sample.alpha = 0
            sample.bounds.size.height = 4
        }) { (complete) in
            sample.removeFromSuperview()
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    var lastWidth: CGFloat = 0
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.bounds.size = self.bounds.insetBy(dx: Constants.margin, dy: 12).size
        contentView.center = self.bounds.center
        
        if lastWidth != contentView.bounds.width {
            clearData()
            totalSamples = floor(contentView.bounds.width * 0.16)
            lastWidth = contentView.bounds.width
            
            sampleRect = CGRect(
                x: 0, y: 0,
                width: contentView.bounds.width / totalSamples,
                height: contentView.bounds.height)
            offsetPerCycle = sampleRect.width/CGFloat(sampleRate)
        }
        
        gradient.frame = CGRect(x: -10, y: 0, width: Constants.margin+16, height: self.bounds.height)
        
        
        
    }
}

//
//  RecordingAudioWaveView.swift
//  Andante
//
//  Created by Miles Vinson on 4/20/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

protocol RecordingAudioWaveViewDelegate: class {
    func visualViewDidBeginDragging()
    func visualViewDidEndDragging()
    func currentAudioTime() -> TimeInterval
    func audioScrollViewDidScroll(time: TimeInterval)
}

class RecordingAudioWaveView: UIView, UIScrollViewDelegate {
    
    public weak var delegate: RecordingAudioWaveViewDelegate?
    
    private let scrollView = UIScrollView()
    private var displayLink: CADisplayLink?
    
    public var scrollGesture: UIPanGestureRecognizer {
        return scrollView.panGestureRecognizer
    }
    
    public var currentLoudness: CGFloat = 0
    
    /**
     Points per second
     */
    private let speed: CGFloat = 72
    
    /**
     Samples of loudness per second
     */
    private let sampleRate: CGFloat = 12
    
    private var lastSampleTime: TimeInterval?
    private var lastIndex: CGFloat = -1
    
    private let leadingGradientView = CAGradientLayer()
    private let trailingGradientView = CAGradientLayer()
    
    private let dimView = UIView()
    private let blockView = UIView()
    
    private let bgColor = Colors.PracticeForegroundColor
    
    private let outlineView = UIView()
            
    init() {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = false
        self.addSubview(scrollView)
        
        dimView.alpha = 0
        dimView.isUserInteractionEnabled = false
        dimView.backgroundColor = bgColor.withAlphaComponent(0.8)
        self.addSubview(dimView)
        
        leadingGradientView.colors = [bgColor.cgColor, bgColor.withAlphaComponent(0).cgColor]
        leadingGradientView.startPoint = CGPoint(x: 0.55, y: 0)
        leadingGradientView.endPoint = CGPoint(x: 1, y: 0)
        self.layer.addSublayer(leadingGradientView)
        
        trailingGradientView.colors = leadingGradientView.colors
        trailingGradientView.startPoint = CGPoint(x: 0.45, y: 0)
        trailingGradientView.endPoint = CGPoint(x: 0, y: 0)
        self.layer.addSublayer(trailingGradientView)
        
        blockView.backgroundColor = bgColor
        blockView.isUserInteractionEnabled = false
        self.addSubview(blockView)
        
        outlineView.backgroundColor = Colors.dynamicColor(
            light: Colors.lightText.withAlphaComponent(0.04),
            dark: UIColor.black.withAlphaComponent(0.05))
        outlineView.alpha = 0
        outlineView.roundCorners(30)
        self.addSubview(outlineView)
        
        self.roundCorners(30)
        self.clipsToBounds = true
        
    }
    
    public func start() {
        scrollView.isScrollEnabled = false
        lastSampleTime = nil
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .current, forMode: .common)
        
    }
    
    public func pause() {
        scrollView.isScrollEnabled = true
        displayLink?.invalidate()
    }
    
    @objc private func update() {
        let audioTime = delegate?.currentAudioTime() ?? 0
        let sampleSpeed = TimeInterval(1/sampleRate)
        
        scrollView.contentSize.width = CGFloat(audioTime + (sampleSpeed)) * (speed)
        if scrollView.contentSize.width > scrollView.frame.width {
            scrollView.contentOffset.x = scrollView.contentSize.width - scrollView.frame.width
        }

        if lastSampleTime == nil || audioTime > lastSampleTime! + sampleSpeed {
            //flooring allows for consistent spacing
            let flooredTime = floor(audioTime/sampleSpeed)*sampleSpeed
            let index = CGFloat(flooredTime / sampleSpeed)
            
            lastSampleTime = flooredTime
            
            if lastIndex < index {
                //to account for ocassional skipping when stopping/starting recording
                for i in Int(lastIndex)..<Int(index)+1 {
                    addLine(at: CGFloat(i+1), loudness: self.currentLoudness)
                }
                
                lastIndex = index
            }
                        
        }
        
    }
    
    public func setSeekTime(time: TimeInterval, overrideZero: Bool = false) {
        //playback time sometimes reports 0 before the real time leading to flickering
         if time == 0 && !overrideZero { return }
        
        let totalTime = delegate?.currentAudioTime() ?? 0
        if totalTime == 0 { return }
        
        let ratio = min(1, max(0, time / totalTime))
        scrollView.contentOffset.x = scrollView.contentSize.width * CGFloat(ratio)
    }
    
    public func getSeekTime() -> TimeInterval {
        let audioTime = delegate?.currentAudioTime() ?? 0
        if audioTime != 0 {
            let width = scrollView.contentSize.width
            let offset = scrollView.contentOffset.x
            let progress = min(1, max(0, offset/width))
            return Double(progress)*audioTime
        }
        else {
            return 0
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.visualViewDidBeginDragging()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        delegate?.visualViewDidEndDragging()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.audioScrollViewDidScroll(time: getSeekTime())
    }
    
    private func addLine(at index: CGFloat, loudness: CGFloat) {
        let frame = CGRect(
            x: index*(speed/sampleRate),
            y: 0,
            width: (speed/sampleRate),
            height: scrollView.bounds.height)
        
        let view = UIView()
        view.backgroundColor = Colors.white
        view.center = CGPoint(x: frame.midX - 2, y: frame.center.y)
        view.bounds.size = CGSize(width: 4, height: max(4, scrollView.bounds.height*min(1, loudness/100)))
        view.roundCorners(2)
        
        let scaleY: CGFloat = 0.35
        let scaleX: CGFloat = 0.6
        let dx = (scaleX*view.bounds.size.width)/2
        view.transform = CGAffineTransform(scaleX: scaleX, y: scaleY).concatenating(CGAffineTransform(translationX: -dx, y: 0))
        view.alpha = 0.5
        
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
            view.transform = .identity
            view.alpha = 1
        }, completion: nil)
        
        scrollView.addSubview(view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public var isLargeMode = false {
        didSet {
            let audioTime = delegate?.currentAudioTime() ?? 0
            let sampleSpeed = TimeInterval(1/sampleRate)
            scrollView.contentSize.width = CGFloat(audioTime + (sampleSpeed)) * (speed)
            scrollView.setContentOffset(scrollView.contentOffset, animated: false)
            
            if isLargeMode {
                animateCornerRadius(self, from: 30, to: 0)
                animateCornerRadius(outlineView, from: 30, to: 0)
            }
            else {
                animateCornerRadius(self, from: 0, to: 30)
                animateCornerRadius(outlineView, from: 0, to: 30)
            }
            
            UIView.animateWithCurve(duration: 0.5, x1: 0.22, y1: 1, x2: 0.36, y2: 1, animation: {
                self.layoutSubviews()
                if self.scrollView.contentSize.width > self.scrollView.frame.width {
                    self.scrollView.contentOffset.x = self.scrollView.contentSize.width - self.scrollView.frame.width
                }
                if self.isLargeMode == false {
                    self.dimView.alpha = 0
                    self.outlineView.alpha = 0
                }
                else {
                    self.outlineView.alpha = 1
                }
            }, completion: {
                if self.isLargeMode {
                    self.dimView.alpha = 1
                }
            })
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == self || view?.superview == self {
            return scrollView
        }
        return view
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        if isLargeMode {
            scrollView.frame = CGRect(x: self.bounds.width/2, y: self.bounds.midY - 18, width: 0, height: 36)
            trailingGradientView.frame = CGRect(x: self.bounds.maxX - 22, y: 0, width: 22, height: self.bounds.height)
            blockView.frame = CGRect(x: self.bounds.maxX, y: 0, width: self.bounds.width, height: self.bounds.height)
            outlineView.frame = self.bounds
        }
        else {
            scrollView.frame = self.bounds.insetBy(dx: 32, dy: 12)
            trailingGradientView.frame = CGRect(x: self.bounds.maxX - 16, y: 0, width: 16, height: self.bounds.height)
            blockView.frame = CGRect(x: scrollView.frame.maxX, y: 0, width: self.bounds.width, height: self.bounds.height)
            outlineView.frame = self.bounds
        }
        
        leadingGradientView.frame = CGRect(x: 0, y: 0, width: 22, height: self.bounds.height)
        
        
        dimView.frame = CGRect(x: self.bounds.midX + 4, y: 0, width: self.bounds.width/2 - 4, height: self.bounds.height)
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        leadingGradientView.colors = [bgColor.cgColor, bgColor.withAlphaComponent(0).cgColor]
        trailingGradientView.colors = leadingGradientView.colors
    }
    
}


//
//  PracticeRecordingBackgroundView.swift
//  Andante
//
//  Created by Miles Vinson on 4/20/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

protocol PracticeRecordingBackgroundViewDelegate: class {
    func recordingViewDidExpandToSheet()
    func recordingViewDidShrinkToPill()
    func currentAudioTime() -> TimeInterval
    func currentPlaybackTime() -> TimeInterval
    func recordingViewDidTapPlay(at time: TimeInterval)
    func recordingViewDidTapPause()
}

class PracticeRecordingBackgroundView: UIView, UIGestureRecognizerDelegate, RecordingAudioWaveViewDelegate {
    
    public weak var delegate: PracticeRecordingBackgroundViewDelegate?
    
    private let contentView = UIView()
    private let contentViewTop = UIView()
    private let contentViewBottom = UIView()
    private let touchGesture = UILongPressGestureRecognizer()
    
    private var touchPoint: CGPoint?
    private var isTouching = false
    
    enum State {
        case small, large
    }
    
    private var state: State = .small
    
    public var hasBottomSafeArea: Bool {
        return self.safeAreaInsets.bottom != 0
    }
    
    private var bottomCornerRadius: CGFloat {
        return hasBottomSafeArea ? 36 : 0
    }
    
    private var topCornerRadius: CGFloat {
        return hasBottomSafeArea ? 20 : 14
    }
    
    private var collapsedCornerRadius: CGFloat {
        return 12
    }
    
    private let recordingView = RecordingAudioWaveView()
    
    private let timeLabel = UILabel()
    
    private let buttonsView = UIView()
    private let playPauseButton = PlaybackButton()
    private let rewindButton = PlaybackButton()
    private let fastForwardButton = PlaybackButton()
    
    private var isPlaying = false
    private var playbackDisplayLink: CADisplayLink?
    
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = .clear
        
        contentView.backgroundColor = .clear
        contentViewTop.backgroundColor = Colors.PracticeForegroundColor
        contentView.addSubview(contentViewTop)
        contentViewBottom.backgroundColor = Colors.PracticeForegroundColor
        contentView.addSubview(contentViewBottom)
        self.addSubview(contentView)
        
        contentViewTop.roundCorners(collapsedCornerRadius)
        contentViewBottom.roundCorners(collapsedCornerRadius)
        
        touchGesture.addTarget(self, action: #selector(handleGesture(_:)))
        touchGesture.minimumPressDuration = 0
        contentView.addGestureRecognizer(touchGesture)
        touchGesture.delegate = self
        
        timeLabel.text = "00:00.00"
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .medium)
        timeLabel.textColor = Colors.white.withAlphaComponent(0.9)
        timeLabel.textAlignment = .center
        timeLabel.alpha = 0
        contentView.addSubview(timeLabel)
        
        buttonsView.alpha = 0
        contentView.addSubview(buttonsView)
        
        //playPauseButton.icon = UIImage(named: "Play")
        playPauseButton.action = {
            self.didTapPlayPause()
        }
        buttonsView.addSubview(playPauseButton)
        
        //fastForwardButton.icon = UIImage(named: "Forward15")
        fastForwardButton.action = {
            self.didTapForward()
        }
        buttonsView.addSubview(fastForwardButton)
        
        //rewindButton.icon = UIImage(named: "Back15")
        rewindButton.action = {
            self.didTapRewind()
        }
        buttonsView.addSubview(rewindButton)
        
        if #available(iOS 13.0, *) {
            playPauseButton.icon = UIImage(
                systemName: "play.fill",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 34, weight: .medium))
            
            fastForwardButton.icon = UIImage(
                systemName: "goforward.15",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .medium))
            
            rewindButton.icon = UIImage(
                systemName: "gobackward.15",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .medium))
        }
        
        recordingView.delegate = self
        contentView.addSubview(recordingView)
        
        self.disableButtons()
        
        self.setShadow(radius: 12, yOffset: 0, opacity: 0.06)
        
        self.isMultipleTouchEnabled = false
    }
    
    private func enableButtons() {
        rewindButton.alpha = 1
        rewindButton.isUserInteractionEnabled = true
        
        playPauseButton.alpha = 1
        playPauseButton.isUserInteractionEnabled = true
        
        fastForwardButton.alpha = 1
        fastForwardButton.isUserInteractionEnabled = true
    }
    
    private func disableButtons() {
        rewindButton.alpha = 0.4
        rewindButton.isUserInteractionEnabled = false
        
        playPauseButton.alpha = 0.4
        playPauseButton.isUserInteractionEnabled = false
        
        fastForwardButton.alpha = 0.4
        fastForwardButton.isUserInteractionEnabled = false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == touchGesture {
            if state == .small {
                return true
            }
            if state == .large && isPlaying {
                return false
            }
            if touch.view == buttonsView || touch.view?.superview == buttonsView {
                return false
            }
            if touch.location(in: self).y > self.bounds.maxY - self.safeAreaInsets.bottom/2 {
                return false
            }
            return true
        }
        else {
            return true
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == touchGesture && otherGestureRecognizer == recordingView.scrollGesture {
            return state == .large
        }
        return false
    }
    
    @objc func didTapPlayPause() {
        if isDragging { return }

        isPlaying = !isPlaying
        if isPlaying {
            startPlayback()
        }
        else {
            stopPlayback()
        }
        
    }
    
    @objc func updatePlayback() {
        let time = delegate?.currentPlaybackTime() ?? 0
        if time >= self.currentTime {
            didTapPlayPause()
            recordingView.setSeekTime(time: currentTime)
        }
        else {
            recordingView.setSeekTime(time: time)
        }
    }
    
    @objc func didTapRewind() {
        if isDragging { return }

        let newTime = max(0, recordingView.getSeekTime() - 15)
        
        if isPlaying {
            stopPlayback(updateButton: false)
            startPlayback(at: newTime)
        }
        else {
            recordingView.setSeekTime(time: newTime, overrideZero: true)
        }
    }
    
    @objc func didTapForward() {
        if isDragging { return }

        let newTime = min(self.currentTime, recordingView.getSeekTime() + 15)
        
        if isPlaying {
            stopPlayback(updateButton: false)
            startPlayback(at: newTime)
        }
        else {
            recordingView.setSeekTime(time: newTime)
        }
    }
    
    public func startPlayback(at time: TimeInterval? = nil) {
        if #available(iOS 13.0, *) {
            playPauseButton.icon = UIImage(
                systemName: "pause.fill",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 34, weight: .medium))
        }
        
        var startTime: TimeInterval
        if let time = time {
            startTime = time
        }
        else {
            startTime = recordingView.getSeekTime()
            if startTime >= self.currentTime {
                startTime = 0
            }
        }
        
        delegate?.recordingViewDidTapPlay(at: startTime)
        
        playbackDisplayLink = CADisplayLink(target: self, selector: #selector(updatePlayback))
        playbackDisplayLink?.add(to: .current, forMode: .common)
    }
    
    public func stopPlayback(updateButton: Bool = true) {
        if updateButton {
            if #available(iOS 13.0, *) {
                playPauseButton.icon = UIImage(
                    systemName: "play.fill",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 34, weight: .medium))
            }
        }
        
        delegate?.recordingViewDidTapPause()
        playbackDisplayLink?.invalidate()
        playbackDisplayLink = nil
    }
    
    public func startRecording() {
        if isPlaying {
            stopPlayback()
        }
        
        recordingView.start()
        
        disableButtons()
    }
    
    public func stopRecording() {
        recordingView.pause()
        
        UIView.animate(withDuration: 0.2) {
            self.enableButtons()
        }
        
    }
    
    private var shouldResumePlaybackAfterDrag = false
    private var isDragging = false
    func visualViewDidBeginDragging() {
        isDragging = true
        if isPlaying {
            stopPlayback(updateButton: false)
            shouldResumePlaybackAfterDrag = true
        }
        else {
            shouldResumePlaybackAfterDrag = false
        }
    }
    
    func visualViewDidEndDragging() {
        isDragging = false
        if shouldResumePlaybackAfterDrag {
            startPlayback()
        }
    }
    
    func audioScrollViewDidScroll(time: TimeInterval) {
        if state == .large {
            timeLabel.text = formatTime(time: time)
        }
    }
    
    public var currentTime: TimeInterval {
        return delegate?.currentAudioTime() ?? 0
    }
    
    func currentAudioTime() -> TimeInterval {
         return self.currentTime
    }
    
    public var currentLoudness: Float = 0 {
        didSet {
            recordingView.currentLoudness = CGFloat(currentLoudness)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if state == .small {
            contentView.bounds.size = CGSize(width: self.bounds.width - 28, height: 60)
            
            let dy: CGFloat = max(CGFloat(12), self.safeAreaInsets.bottom + CGFloat(6))
            contentView.center = CGPoint(
                x: self.bounds.midX,
                y: self.bounds.maxY - dy - CGFloat(30))
            
            contentViewTop.frame = contentView.bounds
            contentViewBottom.frame = contentView.bounds
            
            let timeHeight = timeLabel.sizeThatFits(self.bounds.size).height
            timeLabel.frame = CGRect(x: -32, y: contentView.bounds.midY - timeHeight/2, width: self.bounds.width, height: timeHeight)

            buttonsView.frame = CGRect(x: contentView.bounds.midX - 110, y: contentView.bounds.midY - 48, width: 220, height: 52)
            buttonsView.roundCorners(collapsedCornerRadius)
            
            let buttonSize = CGSize(56)
            let spacing = buttonsView.bounds.width/3
            rewindButton.frame = CGRect(center: CGPoint(x: spacing/2, y: buttonsView.bounds.midY), size: buttonSize)
            playPauseButton.frame = CGRect(center: CGPoint(x: spacing + spacing/2, y: buttonsView.bounds.midY), size: buttonSize)
            fastForwardButton.frame = CGRect(center: CGPoint(x: spacing*2 + spacing/2, y: buttonsView.bounds.midY), size: buttonSize)
            
            recordingView.frame = contentView.bounds
                        
        }
        else {
            contentView.bounds.size = CGSize(width: self.bounds.width, height: self.bounds.height)
            contentView.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
            
            contentViewTop.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: contentView.bounds.height/2 + 50)
            
            contentViewBottom.frame = CGRect(x: 0, y: contentView.bounds.height/2 - 50, width: contentView.bounds.width, height: contentView.bounds.height/2 + 50)
            
            let padding: CGFloat = floor(self.bounds.height*0.09)
            
            let timeHeight = timeLabel.sizeThatFits(self.bounds.size).height - 2
            timeLabel.frame = CGRect(x: 0, y: padding, width: self.bounds.width, height: timeHeight)

            buttonsView.frame = CGRect(x: contentView.bounds.midX - 110, y: self.bounds.maxY - self.safeAreaInsets.bottom - padding - 52, width: 220, height: 52)
            buttonsView.roundCorners(collapsedCornerRadius)
            
            let center = timeLabel.frame.maxY + (buttonsView.frame.minY - timeLabel.frame.maxY)/2
            
            recordingView.frame = CGRect(x: 0, y: center - 45, width: (self.bounds.width), height: 90)
            
            let buttonSize = CGSize(56)
            let spacing = buttonsView.bounds.width/3
            rewindButton.frame = CGRect(center: CGPoint(x: spacing/2, y: buttonsView.bounds.midY), size: buttonSize)
            playPauseButton.frame = CGRect(center: CGPoint(x: spacing + spacing/2, y: buttonsView.bounds.midY), size: buttonSize)
            fastForwardButton.frame = CGRect(center: CGPoint(x: spacing*2 + spacing/2, y: buttonsView.bounds.midY), size: buttonSize)
        }
        
        
        
        
    }
    
    public func setState(_ state: PracticeRecordingBackgroundView.State) {
        
    }
    
    
    
    
    
    
    
    
    //MARK: - Gesture
    
    @objc func handleGesture(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
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
    
    func touchDown() {
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.contentView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }, completion: nil)
        
        if !hasBottomSafeArea && self.state == .large {
            animateCornerRadius(contentViewBottom, from: bottomCornerRadius, to: topCornerRadius)
        }
    }
    
    func touchUp(_ successful: Bool) {
        
        if successful {
            if self.state == .small {
                self.state = .large
                self.delegate?.recordingViewDidExpandToSheet()
                
                animateCornerRadius(contentViewTop, from: collapsedCornerRadius, to: topCornerRadius)
                animateCornerRadius(contentViewBottom, from: collapsedCornerRadius, to: bottomCornerRadius)
                
                UIView.animate(withDuration: 0.25, delay: 0.1, options: .curveEaseInOut, animations: {
                    self.buttonsView.alpha = 1
                    self.timeLabel.alpha = 1
                }, completion: nil)
            }
            else {
                self.state = .small
                self.delegate?.recordingViewDidShrinkToPill()
                
                animateCornerRadius(contentViewTop, from: topCornerRadius, to: collapsedCornerRadius)
                animateCornerRadius(contentViewBottom, from: contentViewBottom.layer.cornerRadius, to: collapsedCornerRadius)
                
                UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseInOut, animations: {
                    self.buttonsView.alpha = 0
                    self.timeLabel.alpha = 0
                }, completion: nil)
            }

            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.76, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.contentView.transform = .identity
                self.layoutSubviews()
            }, completion: nil)
            
            self.recordingView.isLargeMode = self.state == .large
            
            
        }
        else {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.contentView.transform = .identity
            }, completion: nil)
            
            if self.state == .large {
                if !hasBottomSafeArea {
                    animateCornerRadius(contentViewBottom, from: bottomCornerRadius, to: 0)
                }
            }
        }
        
        
        
    }
    
    private func formatTime(time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milli = Int((time - floor(time))*100)
        
        if hours != 0 {
            return String(format:"%02i", hours) + String(format:":%02i", (minutes % 60)) + String(format:":%02i", seconds) + String(format:".%02i", milli)
        }
        
        return String(format:"%02i", minutes) + String(format:":%02i", seconds) + String(format:".%02i", milli)
    }
}

class PlaybackButton: CustomButton {
    
    public var bgInset: UIEdgeInsets = UIEdgeInsets(-6)
    public var highlightColor: UIColor = Colors.lightColor
    
    private let iconBG = UIView()
    private let iconView = UIImageView()
    public var icon: UIImage? {
        didSet {
            iconView.image = icon
            iconView.setImageColor(color: color)
        }
    }
    
    public var color: UIColor = Colors.white {
        didSet {
            iconView.setImageColor(color: color)
        }
    }
    
    override init() {
        super.init()
        
        self.addSubview(iconBG)
        iconBG.addSubview(iconView)
        iconBG.isUserInteractionEnabled = false
        
        self.highlightAction = {
            [weak self] isHighlighted in
            guard let self = self else { return }
            
            if isHighlighted {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [.curveEaseOut], animations: {
                    self.iconBG.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
                }, completion: nil)
                UIView.animate(withDuration: 0.2) {
                    self.iconBG.backgroundColor = self.highlightColor
                }
            }
            else {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                    self.iconBG.transform = .identity
                }, completion: nil)
                UIView.animate(withDuration: 0.35) {
                    self.iconBG.backgroundColor = .clear
                }
            }
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        iconBG.roundCorners(nil, prefersContinuous: false)
        iconBG.bounds.size = self.bounds.inset(by: bgInset).size
        iconBG.center = self.bounds.center
        
        iconView.sizeToFit()
        iconView.center = iconBG.bounds.center
        
    }
}

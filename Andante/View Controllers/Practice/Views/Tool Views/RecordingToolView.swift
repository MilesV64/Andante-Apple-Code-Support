//
//  RecordingToolView.swift
//  Andante
//
//  Created by Miles Vinson on 7/30/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

protocol RecordingToolViewDelegate: class {
    func currentAudioTime() -> TimeInterval
    func currentPlaybackTime() -> TimeInterval
    func recordingViewDidTapPlay(at time: TimeInterval)
    func recordingViewDidTapPause()
    func recordingViewDidTapDelete()
}

class RecordingToolView: PracticeToolView {
    
    public weak var delegate: RecordingToolViewDelegate?
    
    private let audioWaveView = AudioWaveView()
    private let playerView = PlayerView()
    
    enum State {
        case inactive, recording, playing
    }
    
    public var isRecording: Bool {
        return self.state == .recording
    }
    
    public var isPlayingAudio: Bool {
        return self.state == .playing
    }
    
    private var state: State = .inactive
    
    public var currentLoudness: Float = 0 {
        didSet {
            audioWaveView.currentLoudness = CGFloat(currentLoudness)
        }
    }
    
    private var currentTime: TimeInterval {
        return delegate?.currentAudioTime() ?? 0
    }
    
    public var deleteButton: UIView {
        return playerView.deleteButton
    }
    
    public var deleteButtonSourceRect: CGRect {
        return CGRect(
            x: playerView.deleteButton.bounds.midX - 1,
            y: playerView.deleteButton.bounds.minY - 1,
            width: 2, height: 2)
    }
    
    private var isPlaying = false
    private var playbackDisplayLink: CADisplayLink?
    
    private struct DragState {
        var isDragging = false
        var shouldResumePlaybackAfterDragging = false
    }
    
    private var dragState = DragState()
    
    override init() {
        super.init()
        
        contentView.addSubview(audioWaveView)
        
        playerView.alpha = 0
        playerView.slider.delegate = self
        playerView.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        
        playerView.playAction = {
            [weak self] in
            guard let self = self else { return }
            if self.dragState.isDragging { return }
            self.startPlayback()
        }
        
        playerView.pauseAction = {
            [weak self] in
            guard let self = self else { return }
            if self.dragState.isDragging { return }
            self.stopPlayback()
        }
        
        playerView.deleteAction = {
            [weak self] in
            guard let self = self else { return }
            if self.dragState.isDragging { return }
            
            self.delegate?.recordingViewDidTapDelete()
        }
        
        contentView.addSubview(playerView)
        
    }
    
    public func setPlaybackPoint(_ value: CGFloat) {
        playerView.slider.value = value
    }
    
    public func delete() {
        pauseAudio()
        audioWaveView.clearData()
        super.hide()
        DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
            [weak self] in
            guard let self = self else { return }
            self.setState(.recording)
            self.state = .inactive
        }
        
    }
    
    private func startPlayback(at time: TimeInterval? = nil) {
        var startTime: TimeInterval
        if let time = time {
            startTime = time
        }
        else {
            startTime = playerView.sliderValue*self.currentTime
            if startTime >= self.currentTime {
                startTime = -1
            }
        }
        
        delegate?.recordingViewDidTapPlay(at: startTime)
        
        isPlaying = true
        playbackDisplayLink = CADisplayLink(target: self, selector: #selector(updatePlayback))
        playbackDisplayLink?.add(to: .current, forMode: .common)
        
        self.state = .playing
    }
    
    public func pauseAudio() {
        stopPlayback()
        playerView.setPlaybackState(false)
    }
    
    public func playAudio() {
        startPlayback()
        playerView.setPlaybackState(true)
    }
    
    private func stopPlayback() {
        if !isPlaying { return }
        
        delegate?.recordingViewDidTapPause()
        isPlaying = false
        playbackDisplayLink?.invalidate()
        playbackDisplayLink = nil
        
        self.state = .inactive
    }
    
    public func didFinishPlaying() {
        stopPlayback()
        playerView.setPlaybackState(false)
        playerView.sliderValue = 1
    }
    
    @objc func updatePlayback() {
        var time = delegate?.currentPlaybackTime() ?? 0
        let totalTime = self.currentTime
        
        //prevents flickering, -1 is set to represent 0 when i actually do want it to be 0
        if time == 0 {
            return
        }
        else if time == -1 {
            time = 0
        }
        
        if time >= totalTime {
            stopPlayback()
            playerView.setPlaybackState(false)
            playerView.sliderValue = 1
        }
        else {
            playerView.sliderValue = time/totalTime
        }
    }
    
    public func showPlayback() {
        self.state = .recording
        setState(.playing)
        super.show()
    }
    
    override func show(delay: TimeInterval = 0) {
        super.show(delay: 0)
        
        setState(.recording)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            [weak self] in
            guard let self = self else { return }
            self.audioWaveView.start()
        }
        
        
    }
    
    override func hide(delay: TimeInterval = 0) {
        
        if state == .recording {
            setState(.playing)
            audioWaveView.pause()
        }
        else {
            super.hide(delay: delay)
        }
        
    }
    
    private func setState(_ state: State) {
        let currentView: UIView = self.state == .recording ? audioWaveView : playerView
        let newView: UIView = state == .recording ? audioWaveView : playerView
        
        self.state = state
        
        UIView.animate(withDuration: 0.15, delay: 0, options: [], animations: {
            currentView.alpha = 0
        }, completion: { complete in
            currentView.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        })
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            newView.alpha = 1
            newView.transform = .identity
        }, completion: nil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        audioWaveView.bounds.size = contentView.bounds.size
        audioWaveView.center = contentView.center
        
        playerView.bounds.size = contentView.bounds.size
        playerView.center = contentView.center
        
    }
}

extension RecordingToolView: RecordingPlayerSliderDelegate {
    
    func slider(didBeginEditing: Bool) {
        dragState.isDragging = true
        dragState.shouldResumePlaybackAfterDragging = isPlaying
        
        if isPlaying {
            stopPlayback()
        }
                
    }
    
    func slider(didEndEditing: Bool) {
        dragState.isDragging = false
        
        if dragState.shouldResumePlaybackAfterDragging {
            var startTime = playerView.sliderValue*self.currentTime
            if startTime > self.currentTime {
                startTime = self.currentTime
            }
            startPlayback(at: startTime)
        }
    }
    
    func slider(didChange value: CGFloat) {
        
        
    }
    
}

class PlayerView: UIView {
    
    private let playButton = PlaybackButton()
    public let slider = RecordingPlayerSlider()
    public let deleteButton = UIButton(type: .system)
    private var isPlaying = false
    
    public var playAction: (()->Void)?
    public var pauseAction: (()->Void)?
    public var deleteAction: (()->Void)?
    
    public var sliderValue: Double {
        get {
            return Double(slider.value)
        }
        set {
            slider.value = CGFloat(newValue)
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        updatePlayButton()
        playButton.bgInset = UIEdgeInsets(6)
        playButton.highlightColor = PracticeColors.lightFill
        playButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.togglePlayButton()
        }
        playButton.color = PracticeColors.text
        self.addSubview(playButton)
        
        slider.margins = .zero
        slider.color = PracticeColors.purple
        slider.maxTrackColor = PracticeColors.lightFill
        self.addSubview(slider)
        
        deleteButton.setImage(UIImage(name: "xmark.circle.fill", pointSize: 13, weight: .semibold), for: .normal)
        deleteButton.tintColor = PracticeColors.lightText
        deleteButton.addTarget(self, action: #selector(didTapDelete), for: .touchUpInside)
        self.addSubview(deleteButton)
    }
    
    @objc func didTapDelete() {
        deleteAction?()
    }
    
    public func setPlaybackState(_ playing: Bool) {
        isPlaying = playing
        updatePlayButton()
    }
    
    private func togglePlayButton() {
        isPlaying = !isPlaying
        updatePlayButton()
        
        isPlaying ? playAction?() : pauseAction?()
    }
    
    private func updatePlayButton() {
        playButton.icon = UIImage(
            name: isPlaying ? "pause.fill" : "play.fill",
            pointSize: 20,
            weight: .semibold)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        playButton.frame = CGRect(x: 0, y: 0, width: self.bounds.height, height: self.bounds.height)
        
        deleteButton.frame = CGRect(
            x: self.bounds.maxX - 40 - 8, y: 6,
            width: 40, height: self.bounds.height-12)
        
        slider.frame = CGRect(
            from: CGPoint(x: playButton.frame.maxX + 4, y: 0),
            to: CGPoint(x: deleteButton.frame.minX - 8, y: self.bounds.maxY))
        
        
        
    }
}

//
//  RecordingPlayerView.swift
//  Andante
//
//  Created by Miles Vinson on 8/2/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class RecordingPlayerView: UIView, RecordingPlayerSliderDelegate, AVAudioPlayerDelegate {
    
    public var sessionTitle: String = "Practice"
            
    public var recordings: [CDRecording] = []
    private var recordingAssets: [AVAsset] = []
    private var duration: TimeInterval = 0
    
    private let slider = RecordingPlayerSlider()
        
    private let minLabel = UILabel()
    private let maxLabel = UILabel()
    
    private let playPauseButton = PlaybackButton()
    private var isPlaying = false
    public var isPlayingAudio: Bool {
        return isPlaying
    }
    
    private let rewindButton = PlaybackButton()
    private let fastForwardButton = PlaybackButton()
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric,
                      height: 150)
    }
    
    enum AudioState {
        case playing, paused, idle
    }
    
    private var shouldResumeAfterInterruption = false
    
    private var audioState: AudioState = .idle
    
    private var queuePlayer = AVQueuePlayer()
    
    private var displayLink: CADisplayLink?
        
    private var isDoneExporting = false
    
    private var loadingView: LoadingView?
    
    /**
     True once the play button has been pressed once; delayed until then so it doesnt take over sound until it has to
     */
    private var didSetupAudio = false
    
    public var sliderGesture: UILongPressGestureRecognizer {
        return slider.panGesture
    }
    
    init(recordings: [CDRecording]) {
        self.recordings = recordings

        super.init(frame: .zero)
        
        let directory = FileManager.default.temporaryDirectory
        let assetOpts = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        for recording in recordings {
            let filename = "\(UUID().uuidString).m4a"
            let url = directory.appendingPathComponent(filename)
            do {
                try recording.recordingData?.write(to: url)
                
                let asset = AVURLAsset(url: url, options: assetOpts)
                self.recordingAssets.append(asset)
            } catch {
                print(error)
            }
        }
        
        setupQueuePlayer()
        
        slider.delegate = self
        self.addSubview(slider)
        
        minLabel.text = formatTime(time: 0)
        minLabel.textColor = Colors.lightText
        minLabel.font = Fonts.regular.withSize(14)
        minLabel.alpha = 0.6
        self.addSubview(minLabel)
        
        maxLabel.textColor = Colors.lightText
        maxLabel.font = Fonts.regular.withSize(14)
        maxLabel.textAlignment = .right
        maxLabel.alpha = 0.6
        self.addSubview(maxLabel)
        
        playPauseButton.icon = UIImage(name: "play.fill", pointSize: 34, weight: .medium)
        playPauseButton.action = {
            [weak self] in
            guard let self = self else { return }
            
            self.didTapPlayPause()
        }
        playPauseButton.color = Colors.text
        self.addSubview(playPauseButton)
        
        fastForwardButton.icon = UIImage(name: "goforward.15", pointSize: 24, weight: .medium)
        fastForwardButton.action = {
            [weak self] in
            guard let self = self else { return }
            
            self.fastForward()
        }
        fastForwardButton.color = Colors.text
        self.addSubview(fastForwardButton)
        
        rewindButton.icon = UIImage(name: "gobackward.15", pointSize: 24, weight: .medium)
        rewindButton.action = {
            [weak self] in
            guard let self = self else { return }
            
            self.back()
        }
        rewindButton.color = Colors.text
        self.addSubview(rewindButton)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil)
        
        notificationCenter.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil)
    }
    
    deinit {
        for asset in self.recordingAssets {
            if let asset = asset as? AVURLAsset {
                try? FileManager.default.removeItem(at: asset.url)
            }
        }
    }
    
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }

        if type == .began {
            if audioState == .playing {
                pause()
                shouldResumeAfterInterruption = audioState == .playing
            }
        }
        else if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) && shouldResumeAfterInterruption {
                    play()
                } else {
                    // Interruption Ended - playback should NOT resume
                }
            }
        }
    }
    
    @objc func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue) else {
                return
        }
        
        if reason == .oldDeviceUnavailable {
            self.pause()
        }
        else if reason == .newDeviceAvailable {
            self.play()
        }
        
    }

    func setupQueuePlayer() {
        
        setCurrentTime(0)
        
        self.duration = getRecordingDuration()

        self.maxLabel.text = self.formatTime(time: duration)
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public func stopAudio() {
        
        self.audioState = .idle
        self.displayLink?.invalidate()
        playPauseButton.icon = UIImage(name: "play.fill", pointSize: 34, weight: .medium)
        isPlaying = false
        
        queuePlayer.setVolume(0, duration: 0.25) {
            //purposefully strong reference to self to preserve allocation until the fade is complete
            self.queuePlayer.pause()
            self.queuePlayer.removeAllItems()
            self.endAudioSession()
        }
 
        removeControls()
    }
    
    public func pauseAudio() {
        pause()
    }
    
    private func setPlayPauseButton(_ playing: Bool) {
        if playing {
            playPauseButton.icon = UIImage(name: "pause.fill", pointSize: 34, weight: .medium)
        }
        else {
            playPauseButton.icon = UIImage(name: "play.fill", pointSize: 34, weight: .medium)
        }
    }
    
    @objc private func didTapPlayPause() {
        if audioState == .playing {
            pause()
        }
        else {
            play()
        }
    }
    
    public func play(_ updateButton: Bool = true) {
                
        if !didSetupAudio {
            didSetupAudio = true
            
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                print(error)
            }
            
            setupRemoteControls()
        }
        
        if updateButton {
            setPlayPauseButton(true)
        }
        
        self.audioState = .playing
        updateNowPlaying()
        
        if queuePlayer.isPlaying {
            queuePlayer.setVolume(1, duration: 0.15)
        } else {
            queuePlayer.volume = 0
            queuePlayer.play()
            queuePlayer.setVolume(1, duration: 0.15)
        }

        displayLink = CADisplayLink(target: self, selector: #selector(updateSlider))
        displayLink?.add(to: .current, forMode: .common)
        
    }
    
    public func pause(_ updateButton: Bool = true) {
        if updateButton {
            setPlayPauseButton(false)
        }
        self.audioState = .paused
        updateNowPlaying()
        
        queuePlayer.setVolume(0, duration: 0.2) {
            [weak self] in
            guard let self = self else { return }
            
            if self.audioState == .paused {
                self.queuePlayer.pause()
            }
            
        }

        displayLink?.invalidate()
    }
    
    func setupRemoteControls() {
        let center = MPRemoteCommandCenter.shared()
        
        center.playCommand.addTarget {
            [weak self] event in
            guard let self = self else { return .commandFailed }
            
            if self.audioState != .playing {
                self.play()
                return .success
            }
            return .commandFailed
        }

        center.pauseCommand.addTarget {
            [weak self] event in
            guard let self = self else { return .commandFailed }
            
            if self.audioState == .playing {
                self.pause()
                return .success
            }
            return .commandFailed
        }
        
        center.changePlaybackPositionCommand.addTarget {
            [weak self] event in
            guard let self = self else { return .commandFailed }
            
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                self.setCurrentTime(event.positionTime)
                if self.audioState == .playing {
                    self.queuePlayer.play()
                }
                return .success
            }
            
            return .commandFailed
        }
        
        setupNowPlaying()
    }
    
    func setupNowPlaying() {
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = sessionTitle
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Andante"

        if let image = UIImage(named: "AppIcon") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in
                return image
            }
        }
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = getCurrentTime()
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1

        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func updateNowPlaying() {
        // Define Now Playing Info
        if MPNowPlayingInfoCenter.default().nowPlayingInfo == nil { return }
        
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo!

        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = getCurrentTime()
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = audioState == .playing ? 1 : 0

        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func removeControls() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.isEnabled = false
        center.pauseCommand.isEnabled = false
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    
    @objc private func fastForward() {
        setCurrentTime(min(duration, getCurrentTime() + 15))
        
        if audioState == .playing {
            queuePlayer.play()
        }
        
        updateSlider()
        updateNowPlaying()
    }
    
    @objc private func back() {
        let newtime = max(0, getCurrentTime() - 15)
        setCurrentTime(newtime)
        
        if audioState == .playing {
            queuePlayer.play()
        }
        
        updateSlider(forceZero: newtime == 0)
        updateNowPlaying()
    }
    
    @objc private func updateSlider(forceZero: Bool = false) {
        if forceZero {
            self.slider.value = 0
            self.minLabel.text = formatTime(time: 0)
            return
        }
        
        if duration == 0 { return }
        if isDragging { return }
        
        let currentTime = getCurrentTime()
        
        if currentTime == -1 {
            return
        }
        
        let normalizedTime = CGFloat(currentTime / duration)
        
        self.slider.value = normalizedTime
        
        self.minLabel.text = formatTime(time: currentTime)
    }
    
    
    private var isDragging = false

    func slider(didBeginEditing: Bool) {
        isPlaying = audioState == .playing
        
        if isPlaying {
            pause(false)
        }
       
        isDragging = true
        updateLabelPositions()
    }
    
    func slider(didEndEditing: Bool) {
        setCurrentTime(TimeInterval(slider.value) * duration)
        
        if isPlaying {
            play(false)
        }
        
        isDragging = false
        updateLabelPositions()
    }
    
    func slider(didChange value: CGFloat) {
        let currentTime = TimeInterval(value) * duration
        
        self.minLabel.text = formatTime(time: currentTime)
        updateLabelPositions()
    }
    
    private func updateLabelPositions() {
        var minTransform: CGAffineTransform = .identity
        var maxTransform: CGAffineTransform = .identity
        
        if isDragging {
            
            let minFrame = (origin: CGFloat(0), width: minLabel.sizeThatFits(self.bounds.size).width)
            let maxFrame = (origin: self.bounds.maxX - 0 - minLabel.sizeThatFits(self.bounds.size).width,
                            width: minLabel.sizeThatFits(self.bounds.size).width)
            
            let thumbPosition = slider.thumbFrame.minX + slider.thumbFrame.width/2
            
            if thumbPosition <= minFrame.origin + minFrame.width + 12 {
                minTransform = CGAffineTransform(translationX: 0, y: 12)
            }
            
            if thumbPosition >= maxFrame.origin - 12 {
                maxTransform = CGAffineTransform(translationX: 0, y: 12)
            }
            
        }
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: [.curveEaseOut], animations: {
            self.minLabel.transform = minTransform
            self.maxLabel.transform = maxTransform
        }, completion: nil)
        
        
    }
    
    @objc func playerDidFinishPlaying(sender: Notification) {
        queuePlayer.pause()
        displayLink?.invalidate()
        setCurrentTime(-1)
        updateSlider()
        playPauseButton.icon = UIImage(name: "play.fill", pointSize: 34, weight: .medium)
        isPlaying = false
        audioState = .idle
        updateNowPlaying()
        endAudioSession()
    }
    
    private func endAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print(error)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let margin: CGFloat = 0
        
        slider.frame = CGRect(x: 0, y: 0,
                              width: self.bounds.width,
                              height: 52)
        
        let minLabelFrame = CGRect(
            x: margin,
            y: slider.frame.maxY - 16,
            width: self.bounds.width/2,
            height: 12)
        minLabel.bounds.size = minLabelFrame.size
        minLabel.center = minLabelFrame.center
        
        let maxLabelFrame = CGRect(
            x: self.bounds.midX,
            y: slider.frame.maxY - 16,
            width: self.bounds.width/2 - margin,
            height: 12)
        maxLabel.bounds.size = maxLabelFrame.size
        maxLabel.center = maxLabelFrame.center
        
        playPauseButton.frame = CGRect(x: self.bounds.midX - 31,
                                       y: slider.frame.maxY,
                                       width: 54, height: 54)
        
        rewindButton.frame = playPauseButton.frame.offsetBy(dx: -18 - playPauseButton.bounds.width, dy: 0).insetBy(dx: 3, dy: 3)
        fastForwardButton.frame = playPauseButton.frame.offsetBy(dx: 18 + playPauseButton.bounds.width, dy: 0).insetBy(dx: 3, dy: 3)
        
        loadingView?.frame = self.bounds
        
    }
    
    private func formatTime(time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        
        if hours != 0 {
            return String(hours) + String(format:":%02i", (minutes % 60)) + String(format:":%02i", seconds)
        }
        
        
        return "\(minutes)" + String(format:":%02i", seconds)
        
    }
}

protocol RecordingPlayerSliderDelegate: class {
    func slider(didBeginEditing: Bool)
    func slider(didChange value: CGFloat)
    func slider(didEndEditing: Bool)
}

class RecordingPlayerSlider: UIView {
    
    public weak var delegate: RecordingPlayerSliderDelegate?
    
    private let minTrackView = UIView()
    private let maxTrackView = UIView()
    private let thumbView = UIView()
    
    private let thumbGestureView = UIView()
    public let panGesture = UILongPressGestureRecognizer()
    
    public var margins = UIEdgeInsets(0)
    
    public var value: CGFloat = 0 {
        didSet {
            self.layoutThumbView()
        }
    }
    
    private var width: CGFloat {
        return self.bounds.width - margins.left - margins.right
    }
    
    private var unemphasizedColor: UIColor {
        return UIColor.systemGray
    }
    
    public var maxTrackColor: UIColor? {
        get {
            return maxTrackView.backgroundColor
        }
        set {
            maxTrackView.backgroundColor = newValue
        }
    }
    
    public var color: UIColor? {
        get {
            return minTrackView.backgroundColor
        }
        set {
            minTrackView.backgroundColor = newValue
            thumbView.backgroundColor = newValue
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        
        maxTrackView.backgroundColor = Colors.lightColor
        maxTrackView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        self.addSubview(maxTrackView)
        
        minTrackView.backgroundColor = Colors.orange
        minTrackView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        self.addSubview(minTrackView)
                
        thumbView.backgroundColor = Colors.orange
        //thumbView.setShadow(radius: 4, yOffset: 2, opacity: 0.08)
        self.addSubview(thumbView)
        
        thumbGestureView.addGestureRecognizer(panGesture)
        panGesture.minimumPressDuration = 0
        panGesture.addTarget(self, action: #selector(didPan(_:)))
        thumbGestureView.backgroundColor = .clear
        self.addSubview(thumbGestureView)
        
    }
    
    private var touchOffset: CGFloat = 0
    
    public var thumbFrame: CGRect {
        return CGRect(center: thumbView.center, size: thumbView.bounds.size)
    }
        
    @objc private func didPan(_ gesture: UILongPressGestureRecognizer) {
        
        if gesture.state == .began {
            delegate?.slider(didBeginEditing: true)
            
            let touchPoint = gesture.location(in: self).x
            let scaledLocation = (touchPoint - margins.left) / width
            touchOffset = scaledLocation - self.value
            
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                self.thumbView.transform = CGAffineTransform(scaleX: 3.5, y: 3.5)
            }, completion: nil)
            
        }
        else if gesture.state == .changed {
            let location = gesture.location(in: self).x
            
            let scaledLocation = (location - margins.left) / width
            
            self.value = max(0, min(1, scaledLocation - touchOffset))
            delegate?.slider(didChange: value)
            
        }
        else {
            delegate?.slider(didEndEditing: true)
            
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.74, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                self.thumbView.transform = .identity
            }, completion: nil)
            
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let trackHeight: CGFloat = 4
        
        maxTrackView.frame = CGRect(
            x: margins.left,
            y: self.bounds.midY - trackHeight/2,
            width: width,
            height: trackHeight)
        maxTrackView.roundCorners(prefersContinuous: false)
        
        
        thumbView.bounds.size = CGSize(width: 10, height: 10)
        thumbView.roundCorners(prefersContinuous: false)
        
        thumbGestureView.bounds.size = CGSize(width: 52, height: 52)
        
        layoutThumbView()
                
    }
    
    private func layoutThumbView() {
        //so the edges of the thumb are constrained within the track
        let constrainedWidth: CGFloat = width - CGFloat(8)
        let margin: CGFloat = margins.left + 4
        thumbView.center = CGPoint(x: margin + (constrainedWidth * value),
                                   y: self.bounds.midY)
        
        thumbGestureView.center = thumbView.center
        
        minTrackView.frame = CGRect(
            x: margins.left,
            y: self.bounds.midY - maxTrackView.bounds.height/2,
            width: width*value,
            height: maxTrackView.bounds.height)
        minTrackView.roundCorners(prefersContinuous: false)
        
    }
}

class InsetButton: UIButton {
    
    public var inset: CGFloat
    
    init(inset: CGFloat) {
        self.inset = inset
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if isUserInteractionEnabled && self.bounds.insetBy(dx: -inset, dy: -inset).contains(point) {
            return self
        }
        else {
            return super.hitTest(point, with: event)
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                self.alpha = 0.2
            }
            else {
                UIView.animate(withDuration: 0.35) {
                    self.alpha = 1
                }
            }
        }
    }
}

fileprivate class LoadingView: UIView {
    
    private let indicator = UIActivityIndicatorView()
    private let label = UILabel()
    
    public func stopAnimating() {
        indicator.stopAnimating()
    }
    
    init() {
        super.init(frame: .zero)
        
        self.addSubview(indicator)
        
        label.text = "Preparing your recording..."
        label.textColor = Colors.text.withAlphaComponent(0.8)
        label.font = Fonts.semibold.withSize(14)
        self.addSubview(label)
        
        
        indicator.startAnimating()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        indicator.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        
        label.sizeToFit()
        label.center = CGPoint(x: self.bounds.midX, y: indicator.frame.maxY + 34)
        
    }
}

extension RecordingPlayerView {
    
    func setCurrentTime(_ time: TimeInterval) {
        let assetKeys = ["playable"]
        let playerItems = self.recordingAssets.map {
            AVPlayerItem(asset: $0, automaticallyLoadedAssetKeys: assetKeys)
        }
        
        if let item = playerItems.last {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.playerDidFinishPlaying(sender:)),
                name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                object: item)
        }

        self.queuePlayer = AVQueuePlayer(items: playerItems)
        self.queuePlayer.actionAtItemEnd = .advance
                
        if time > 0 {
            var actualTime: TimeInterval = time
            for item in recordingAssets {
                
                let itemSeconds = item.duration.seconds
                if itemSeconds < actualTime {
                    actualTime -= itemSeconds
                    queuePlayer.advanceToNextItem()
                }
                else {
                    break
                }
            }
            
            queuePlayer.seek(to: CMTime(seconds: actualTime, preferredTimescale: 1000000))
        }
        
    }
    
    func getRecordingDuration() -> TimeInterval {
        var time: TimeInterval = 0
        for item in recordingAssets {
            time += item.duration.seconds
        }
        return time
    }
    
    func getCurrentTime() -> TimeInterval {
        let time = queuePlayer.currentTime()
        
        if time.seconds == 0 {
            return -1
        }
        
        let elapsedTime = queueDurationUntilCurrentItem()
        let currentTime = max(0, time.seconds)

        return elapsedTime + currentTime
    }
    
    func queueDurationUntilCurrentItem() -> TimeInterval {
        var time: TimeInterval = 0
        
        //the items in the queue, including the current item, excluding previous items
        //note that the queueplayer deletes items after its done playing them
        
        let itemCount = queuePlayer.items().count
        let totalItems = recordingAssets.count
        
        let elapsedItemCount = totalItems - itemCount
        
        if elapsedItemCount == 0 { return 0 }
        
        for i in 0..<elapsedItemCount {
            let elapsedItem = recordingAssets[i]
            time += elapsedItem.duration.seconds
        }
        
        return time
        
    }
    
}

extension AVQueuePlayer {
    
    var isPlaying: Bool {
        return self.rate != 0 && self.error == nil
    }
    
    func setVolume(_ volume: Float, duration: TimeInterval, completion: (()->Void)? = nil) {
        let currentVolume = self.volume
        
        guard volume != currentVolume else { return }
        
        let interval: Float = 0.02
        let range = volume - currentVolume
        let step = (range*interval)/Float(duration)
        
        Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: true) {
            [weak self] timer in
            guard let self = self else { return }
            
            let newVolume = self.volume + step
            
            if (step > 0 && newVolume >= volume) || (step < 0 && newVolume <= volume) {
                self.volume = volume
                timer.invalidate()
                completion?()
            }
            else {
                self.volume = newVolume
            }
            
        }
        
    }
    
}

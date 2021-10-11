//
//  PracticeViewController.swift
//  Andante
//
//  Created by Miles Vinson on 4/19/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit
import AVFoundation
import UserNotifications

class SessionModel {
    var practiceTime = 0
    var mood = 3
    var focus = 3
    var notes = ""
    var start = Date()
    var end: Date?
    var recordings: [Data] = []
    var title = ""
}

class PracticeColors {
    class var background: UIColor {
        return Colors.dynamicColor(light: Colors.orange, dark: Colors.backgroundColor)
    }
    
    class var unselectedToolButtonBG: UIColor {
        return Colors.dynamicColor(
            light: Colors.white.withAlphaComponent(0.15),
            dark: PracticeColors.secondaryBackground
        )
    }
    
    class var selectedToolButtonBG: UIColor {
        return Colors.dynamicColor(
            light: Colors.white,
            dark: PracticeColors.text
        )
    }
    
    class var secondaryBackground: UIColor {
        return Colors.foregroundColor
    }
    
    class var lightFill: UIColor {
        return Colors.lightColor
    }
    
    class var text: UIColor {
        return Colors.text
    }
    
    class var lightText: UIColor {
        return Colors.lightText
    }
    
    class var separator: UIColor {
        return Colors.separatorColor
    }
    
    class var purple: UIColor {
        return Colors.orange
    }
}

enum PracticeTool {
    case record, timer, metronome, notes, tuner
    
    var icon: UIImage? {
        switch self {
        case .record: return UIImage(named: "mic")
        case .timer: return UIImage(named: "timer")
        case .metronome: return UIImage(named: "metronome")
        case .notes: return UIImage(named: "speech.bubble")
        case .tuner: return UIImage(named: "tuner")
        }
    }
    
    var selectedIcon: UIImage? {
        switch self {
        case .record: return UIImage(named: "mic.bold")
        case .timer: return UIImage(named: "timer.bold")
        case .metronome: return UIImage(named: "metronome.bold")
        case .notes: return UIImage(named: "speech.bubble")
        case .tuner: return UIImage(named: "tuner")
        }
    }
}

extension Colors {
    class var PracticeBackgroundColor: UIColor {
        return dynamicColor(light: Colors.orange, dark: Colors.foregroundColor)
    }
    
    class var PracticeForegroundColor: UIColor {
        return dynamicColor(light: Colors.text, dark: UIColor("#3C3D45"))
    }
    
    class var PracticeButtonColor: UIColor {
        return dynamicColor(light: Colors.white, dark: UIColor("#E7E9EA"))
    }
}

class PracticeViewController: PracticeAnimationViewController {
    
    public lazy var timerLabel: UILabel = {
        let label = UILabel()
        label.textColor = Colors.white
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 50, weight: .light)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.1
        label.text = "00:00"
        return label
    }()
    
    private lazy var timerLabelOutline: UIView = {
        let view = UIView()
        view.layer.borderColor = Colors.dynamicColor(
            light: Colors.white.withAlphaComponent(0.23),
            dark: Colors.barSeparator).cgColor
        view.layer.borderWidth = 2
        return view
    }()
        
    private let timerLabelTapGesture = UITapGestureRecognizer()
    private let interactionHaptic = UIImpactFeedbackGenerator(style: .light)
    
    public var timerDidUpdateAction: ((String)->Void)?
    
    private var timerManager = TimerManager()
    public var isTimerPaused: Bool {
        return timerManager.currentState == .paused
    }
    
    private let audioNotifictionHandler = AudioNotificationHandler()
    private let audioRecorder = HPRecorder()
    private var recordingChunks: [AVURLAsset] = []
    private var queuePlayer: AVQueuePlayer?
        
    public let doneButton = PushButton()
    public let cancelButton = PushButton()
    
    private let journalButton = PracticeToolButton(.notes)
    private let tunerButton = PracticeToolButton(.tuner)
    private let metronomeButton = PracticeToolButton(.metronome)
    private let timerButton = PracticeToolButton(.timer)
    private let recordButton = PracticeToolButton(.record)
    
    private let metronomeView = MetronomeToolView()
    private let timerView = TimerToolView()
    private let recordView = RecordingToolView()
    
    private var transitionManager: TransitionManager!
    private var confirmView: ConfirmView!
    public let practiceView = UIView()
    
    private let handleView = HandleView()
    
    private weak var tunerViewController: TunerViewController?
    
    private var ongoingSessionUpdateTimer: Timer?
        
    private var session = SessionModel()
    
    private var activeTools: [PracticeTool] = []
    
    private var allowTuner = false
    
    private lazy var clickSound: Sound? = {
        return Sound(url: Bundle.main.url(forResource: "metronome.click", withExtension: "wav")!)
    }()
    
    private lazy var recordStartSound: Sound? = {
        return Sound(url: Bundle.main.url(forResource: "recording.start", withExtension: "wav")!)
    }()
    
    private lazy var recordEndSound: Sound? = {
        return Sound(url: Bundle.main.url(forResource: "recording.end", withExtension: "wav")!)
    }()
    
    private lazy var timerFinishedSound: Sound? = {
        return Sound(url: Bundle.main.url(forResource: "timer.notification", withExtension: "wav")!)
    }()
        
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.modalPresentationCapturesStatusBarAppearance = true
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UNUserNotificationCenter.current().delegate = self
        
        setupInitialUI()
        
        setup()
        
        if CDOngoingSession.ongoingSession == nil {
            CDOngoingSession.createOngoingSession()
        }
        else {
            resumeOngoingSession()
        }
        
        ongoingSessionUpdateTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: {
            [weak self] timer in
            self?.updateOngoingSession()
        })
        
    }
    
    private func updateOngoingSession() {
        CDOngoingSession.ongoingSession?.update(updates: {
            [weak self] session in
            guard let self = self else { return }

            session.lastSave = Date()
            session.isPaused = self.isTimerPaused
            session.start = self.timerManager.startTime ?? Date()
            session.practiceTimeSeconds = Int64(self.timerManager.timerSeconds)

            session.notes = self.session.notes
        })
    }
    
    override func didCollapse() {
        super.didCollapse()
        pauseAudio()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        timerLabelOutline.layer.borderColor = Colors.dynamicColor(
            light: Colors.white.withAlphaComponent(0.25),
            dark: Colors.barSeparator).cgColor
        
        if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            transitionManager.isEnabled = traitCollection.horizontalSizeClass == .compact
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if isAnimating { return }
        
        contentView.contextualFrame = self.view.bounds
                
        practiceView.contextualFrame = self.view.bounds
        
        confirmView.contextualFrame = self.view.bounds
        
        transitionManager.updateLayout()
        
        layoutTools()

        layoutTimer()
        
        layoutOther()
        
        
    }
    
    private var didAnimate = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if didAnimate {
            return
        }
        
        timerLabelOutline.transform = CGAffineTransform(translationX: 0, y: 60)
        timerLabel.transform = CGAffineTransform(translationX: 0, y: 60).concatenating(CGAffineTransform(scaleX: 0.7, y: 0.7))
        
        timerLabelOutline.alpha = 0
        timerLabel.alpha = 0
        
        UIView.animate(withDuration: 1, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [.curveEaseInOut]) {
            self.timerLabelOutline.transform = .identity
            self.timerLabelOutline.alpha = 1
            self.timerLabel.transform = CGAffineTransform(translationX: 0, y: 10).concatenating(CGAffineTransform(scaleX: 0.7, y: 0.7))
        } completion: { (complete) in }
        
        UIView.animate(withDuration: 0.9, delay: 0.35, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [.curveEaseInOut]) {
            self.timerLabel.transform = .identity
            self.timerLabel.alpha = 1
        } completion: { (complete) in }
        
        let delays = [0.2, 0.4, 0.5, 0.6, 0.7].shuffled()
        let tools = [journalButton, tunerButton, timerButton, metronomeButton, recordButton]
        
        for (i, tool) in tools.enumerated() {
            
            tool.alpha = 0
            tool.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            
            UIView.animate(withDuration: 1, delay: delays[i], usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [.curveEaseInOut, .allowUserInteraction]) {
                tool.transform = .identity
                tool.alpha = 1
            } completion: { (complete) in }
            
        }

        
        didAnimate = true
        
    }
    
    private var didAppear = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if didAppear {
            return
        }
        
        interactionHaptic.prepare()

        if let session = CDOngoingSession.ongoingSession {
            timerManager.startTimer(start: session.start ?? Date(), seconds: Int(session.practiceTimeSeconds))
        }
        else {
            timerManager.startTimer()
            self.updateOngoingSession()
        }
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        didAppear = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    
    
    deinit {
        let _ = 10
        print("deinit")
    }
    
    private func resumeOngoingSession() {
        if let session = CDOngoingSession.ongoingSession {
            self.session.notes = session.notes ?? ""
            if !session.isPaused {
                let diff = Int(Date().timeIntervalSince(session.lastSave ?? Date()))
                session.update { (session) in
                    session.practiceTimeSeconds += Int64(diff)
                }
            }
            timerDidUpdate(seconds: Int(session.practiceTimeSeconds))

            session.update { (session) in
                session.isPaused = false
            }
            
            let recordings = session.recordings

            for chunkFilename in recordings {
                let assetOpts = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
                let asset = AVURLAsset(
                    url: RecordingsManager.getRecordingURL(chunkFilename), options: assetOpts)

                self.recordingChunks.append(asset)
            }

            if recordings.count > 0 {
                activeTools.append(.record)
                recordView.showPlayback()
                view.setNeedsLayout()
            }

        }
        
    }
    
}

//MARK: - Initial Setup
private extension PracticeViewController {
    func setupInitialUI() {
        
        view.addSubview(contentView)
        
        self.contentView.backgroundColor = PracticeColors.background
        
        practiceView.backgroundColor = .clear
        self.contentView.addSubview(practiceView)
        
        confirmView = ConfirmView(session)
        self.contentView.addSubview(confirmView)
        
        handleView.color = Colors.white.withAlphaComponent(0.35)
        self.practiceView.addSubview(handleView)

        timerLabelOutline.addGestureRecognizer(timerLabelTapGesture)
        timerLabelTapGesture.addTarget(self, action: #selector(didTapTimerLabel))
        self.practiceView.addSubview(timerLabelOutline)
        
        timerLabel.isUserInteractionEnabled = false
        self.practiceView.addSubview(timerLabel)
        
        recordButton.delegate = self
        self.practiceView.addSubview(recordButton)
        
        doneButton.addTarget(self, action: #selector(didTapDone), for: .touchUpInside)
        doneButton.setTitle("Done", color: PracticeColors.background, font: Fonts.bold.withSize(15))
        doneButton.backgroundColor = PracticeColors.selectedToolButtonBG
        self.practiceView.addSubview(doneButton)
        
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        cancelButton.setTitle("Cancel", color: Colors.white, font: Fonts.medium.withSize(15))
        cancelButton.backgroundColor = PracticeColors.unselectedToolButtonBG
        self.practiceView.addSubview(cancelButton)
        
        [journalButton, tunerButton, metronomeButton, timerButton].forEach { (button) in
            button.delegate = self
            self.practiceView.addSubview(button)
        }
                
        timerView.delegate = self
        self.practiceView.addSubview(timerView)
        
        metronomeView.delegate = self
        self.practiceView.addSubview(metronomeView)
        
        recordView.delegate = self
        self.practiceView.addSubview(recordView)
        
    }
    
    func setup() {
        
        self.practiceView.isMultipleTouchEnabled = false
        
        audioNotifictionHandler.delegate = self
        
        timerManager.delegate = self
        
        audioRecorder.prepare()
        
        DispatchQueue.global(qos: .background).async {
            //so there isn't a delay on the first sound played
            //sound.prepare doesn't seem to work as well as this
//            self.recordStartSound?.volume = 0
//            self.recordStartSound?.play()
//            self.recordStartSound?.stop()
//            self.recordStartSound?.volume = 1
        }
        
        
        transitionManager = TransitionManager(
            firstView: practiceView,
            secondView: confirmView,
            parentView: self.view)
        transitionManager.gesture.delegate = self
        
        transitionManager.isEnabled = traitCollection.horizontalSizeClass == .compact
        
        transitionManager.statusBarHandler = {
            [weak self] style in
            guard let self = self else { return }
            self.statusBarStyle = style
            self.setNeedsStatusBarAppearanceUpdate()
        }
        
        confirmView.cancelHandler = {
            [weak self] in
            guard let self = self else { return }
            self.transitionManager.close()
        }
        
        confirmView.saveAction = {
            [weak self] in
            guard let self = self else { return }
            self.saveSession()
        }
        
        confirmView.premiumHandler = {
            [weak self] in
            guard let self = self else { return }
            self.presentModal(AndanteProViewController(), animated: true, completion: nil)
        }
        
        transitionManager.openHandler = {
            [weak self] in
            guard let self = self else { return }
    
            self.session.start = self.timerManager.startTime ?? Date()
            self.session.practiceTime = self.timerManager.practiceTime
            self.session.end = Date()
            
            self.confirmView.updateCells()
            
        }
        
        transitionManager.didOpenHandler = {
            [weak self] in
            guard let self = self else { return }
            
            self.pauseAudio()
            
            self.isShowingConfirmScreen = true
            
        }
        
        transitionManager.didCloseHandler = {
            [weak self] in
            guard let self = self else { return }
            
            self.isShowingConfirmScreen = false
        }
                
    }
    
    private func pauseAudio() {
        if activeTools.contains(.metronome) {
            didTapToolButton(metronomeButton)
        }
        
        if audioRecorder.isRecording {
            stopRecording()
            recordView.hide()
            recordButton.setState(.inactive)
        }
        else if recordView.isPlayingAudio {
            recordView.pauseAudio()
        }
    }
    
    @objc func didTapDone() {
        if traitCollection.horizontalSizeClass == .compact {
            transitionManager.open()
        }
        else {
            self.session.start = self.timerManager.startTime ?? Date()
            self.session.practiceTime = self.timerManager.practiceTime
            self.session.end = Date()
            
            let vc = ConfirmViewController(self, session: session)
            vc.saveAction = {
                [weak self] in
                guard let self = self else { return }
                self.saveSession(dismiss: false)
 
                self.animateDismiss()
                vc.dismiss(animated: true) {
                    self.dismiss(animated: false, completion: nil)
                }
            }
            
            self.pauseAudio()
            self.presentModal(vc, animated: true, completion: nil)
        }
    }
    
    @objc func didTapCancel() {
        if audioRecorder.isRecording || recordingChunks.count > 0 || timerManager.practiceTime > 1 {
            
            let alert = AreYouSureAlert(title: "Exit Session?", description: "Your progress will not be saved.", destructiveText: "Exit Session", cancelText: "Back", destructiveAction: {
                [weak self] in
                guard let self = self else { return }
                
                self.cleanup()
                self.dismiss(animated: true, completion: nil)
            })
            self.presentAlert(alert, sourceView: cancelButton, arrowDirection: .up)
            
        }
        else {
            DispatchQueue.main.async {
                [weak self] in
                guard let self = self else { return }
                self.cleanup()
                self.dismiss(animated: true, completion: nil)
            }
            
        }
    }
    
    func cleanup(save: Bool = false) {
        self.queuePlayer?.pause()
        self.queuePlayer = nil
        
        if audioRecorder.isRecording {
            let url = audioRecorder.audioFilename
            self.audioRecorder.endRecording()
            do {
                try FileManager.default.removeItem(at: url!)
            }
            catch {
                print(error)
            }
        }
        
        if !save {                        
            do {
                for chunk in recordingChunks {
                    try FileManager.default.removeItem(at: chunk.url)
                }
            }
            catch {
                print(error)
            }
        }
        
        self.timerManager.stopTimer()
        
        if activeTools.contains(.metronome) {
            didTapToolButton(metronomeButton)
        }
        
        ongoingSessionUpdateTimer?.invalidate()

        CDOngoingSession.deleteOngoingSession()
        
        unscheduleTimerNotification()
    }
    
}

//MARK: - Layouts
private extension PracticeViewController {

    func layoutTimer() {
        let size = CGSize(min(300, self.view.bounds.width*0.6))

        
        let standardY = self.view.bounds.height*0.24
        let toolMinY = toolFrame(for: activeTools.count - 1).minY
        
        let toolSpace: CGFloat = self.view.bounds.height * 0.1

        let minY = max(self.view.safeAreaInsets.top + 46, min(standardY, toolMinY - toolSpace - size.height))

        timerLabelOutline.bounds.size = size
        timerLabelOutline.center = CGPoint(
            x: self.view.bounds.midX, y: minY + size.height/2)
        timerLabelOutline.roundCorners(prefersContinuous: false)
        
        timerLabel.bounds.size = timerLabelOutline.bounds.insetBy(dx: 28, dy: 0).size
        timerLabel.center = timerLabelOutline.center
        
    }
    
    func layoutTools() {
        
        let totalWidth = min(self.view.bounds.width - 60, 330)
        let spacing: CGFloat = isSmallScreen() ? 10 : 12
        
        let buttonSize = (totalWidth - (spacing*4))/5

        let minX: CGFloat = self.view.bounds.midX - totalWidth/2
        let minY: CGFloat = self.view.bounds.maxY - self.view.safeAreaInsets.bottom - CGFloat(isSmallScreen() ? 16 : 20) - buttonSize
        
        for (i, button) in [journalButton, tunerButton, timerButton, metronomeButton, recordButton].enumerated() {
            let extra: CGFloat = CGFloat(i)*(buttonSize+spacing)
            button.contextualFrame = CGRect(
                x: minX + extra,
                y: minY,
                width: buttonSize,
                height: buttonSize)
        }
        
        for (i, tool) in activeTools.enumerated() {
            toolView(for: tool).frame = toolFrame(for: i)
        }
        
    }
    
    func toolFrame(for position: Int) -> CGRect {
        //0: bottom, 1: middle, 2: top
        
        let height = PracticeToolView.Height
        let margin: CGFloat = isSmallScreen() ? 18 : self.view.bounds.height * 0.06
        let maxY: CGFloat = journalButton.frame.minY - margin
        let spacing: CGFloat = 12
        
        let width = min(view.bounds.width, 600)
        
        return CGRect(
            x: view.bounds.midX - width/2,
            y: maxY - height - (height+spacing)*CGFloat(position),
            width: width,
            height: height)
        
    }
    
    func layoutOther() {
        
        handleView.frame = CGRect(
            x: 0, y: view.safeAreaInsets.top + 10,
            width: view.bounds.width, height: 20)
        
        doneButton.frame = CGRect(
            x: self.view.bounds.maxX - 80 - (Constants.margin - 3),
            y: self.view.safeAreaInsets.top + 4,
            width: 78, height: 32)
        doneButton.cornerRadius = 16
        
        cancelButton.frame = CGRect(
            x: Constants.margin - 3,
            y: self.view.safeAreaInsets.top + 4,
            width: 80, height: 32)
        cancelButton.cornerRadius = 16
    }
        
}

//MARK: - TimerManager
extension PracticeViewController: TimerManagerDelegate {
    
    func timerDidUpdateMinutes(minutes: Int) {
        
    }
    
    func timerDidUpdate(seconds: Int) {
        let hours = seconds / 3600
        let minutes = seconds / 60
        let sec = seconds % 60
        
        if hours != 0 {
            timerLabel.text = String(hours) + String(format:":%02i", (minutes % 60)) + String(format:":%02i", sec)
        }
        else {
            timerLabel.text = String(format:"%02i", minutes) + String(format:":%02i", sec)
        }
        
        timerDidUpdateAction?(timerLabel.text ?? "")
        
    }
    
}

//MARK: - Selectors
extension PracticeViewController {
    
    @objc func didTapTimerLabel() {
        interactionHaptic.impactOccurred()
        if timerManager.currentState == .running {
            timerManager.pauseTimer()
            self.timerLabelOutline.alpha = 0.5
            self.timerLabel.alpha = 0.5
        }
        else {
            timerManager.resumeTimer()
            UIView.animate(withDuration: 0.25) {
                self.timerLabelOutline.alpha = 1
                self.timerLabel.alpha = 1
            }
        }
    }
    
}

//MARK: - Tool Button Delegate
extension PracticeViewController: PracticeToolButtonDelegate, MetronomeToolViewDelegate {
    
    func toolView(for tool: PracticeTool) -> PracticeToolView {
        switch tool {
        case .metronome:
            return metronomeView
        case .record:
            return recordView
        case .timer:
            return timerView
        default:
            return PracticeToolView()
        }
    }
    
    func didTapToolButton(_ button: PracticeToolButton) {
        let type = button.type
        if type == .notes {
            if Settings.isPremium {
                let vc = NotesViewController()
                
                vc.notes = self.session.notes
                vc.notesAction = {
                    [weak self] notes in
                    guard let self = self else { return }
                    self.session.notes = notes
                }
                vc.closeHandler = {
                    [weak self] in
                    guard let self = self else { return }
                    self.confirmView.updateNotes()
                }
                self.presentModal(vc, animated: true, completion: nil)
            }
            else {
                self.presentModal(AndanteProViewController(), animated: true, completion: nil)
            }
            
            return
        }
        else if type == .tuner {
            self.openTuner()
        }
        else if type == .timer {
            
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
                [weak self] success, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    [weak self] in
                    guard let self = self else { return }
                    self.handleTimerButton(success)
                }
                
                
            }
                        
        }
        else if type == .record {
            handleRecordingButton()
            
        }
        else {
            
            toggleToolButton(button)
        }
        
                
    }
    
    func toggleToolButton(_ button: PracticeToolButton) {
        let type = button.type
        
        self.practiceView.sendSubviewToBack(toolView(for: type))
        
        if let index = activeTools.firstIndex(of: type) {
            
            button.setState(.inactive)

            activeTools.remove(at: index)
            
            toolView(for: type).hide()
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.viewDidLayoutSubviews()
            }, completion: nil)
            
            if type == .metronome {
                timerLabelOutline.layer.borderColor = Colors.dynamicColor(
                    light: Colors.white.withAlphaComponent(0.25),
                    dark: Colors.barSeparator).cgColor
            }
            
        }
        else {
            button.setState(.active)
            var index = 0
            if type == .metronome {
                
                timerLabelOutline.layer.borderColor = UIColor.white.cgColor
                
                if activeTools.count == 0 {
                    activeTools.append(type)
                    index = 0
                }
                else if activeTools.count == 1 {
                    if activeTools[0] == .timer {
                        activeTools.insert(type, at: 0)
                        index = 0
                    }
                    else {
                        activeTools.insert(type, at: 1)
                        index = 1
                    }
                }
                else if activeTools.count == 2 {
                    activeTools.insert(type, at: 1)
                    index = 1
                }
            }
            else if type == .timer {
                activeTools.append(type)
                index = activeTools.count - 1
            }
            else {
                activeTools.insert(type, at: 0)
                index = 0
            }
            
            toolView(for: type).frame = toolFrame(for: index)
            toolView(for: type).show()
            UIView.animate(withDuration: 0.55, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.viewDidLayoutSubviews()
            }, completion: nil)
        }
    }
    
    func metronomeDidTick() {
        if timerManager.currentState == .running {
            
            timerLabelOutline.layer.borderWidth = 12
            timerLabelOutline.animateBorderWidth(duration: 0.2, to: 1.5)
            
            timerLabelOutline.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveLinear, .allowUserInteraction], animations: {
                self.timerLabelOutline.transform = .identity
            }, completion: nil)
        
        }
    }
    
    func handleRecordingButton() {
        if activeTools.contains(.record) {
            if recordView.isRecording {
                recordEndSound?.play()
                stopRecording()
                recordView.hide()
                recordButton.setState(.inactive)
            }
            else {
                self.recordButton.setState(.active)
                self.recordingButtonDidStartRecording()
            }
        }
        else {
            checkAudioPermissions {
                [weak self] success in
                guard let self = self else { return }
                
                if success {
                    self.toggleToolButton(self.recordButton)
                    self.recordingButtonDidStartRecording()
                }
                else {
                    self.audioPermissionsFailed()
                }
            }
        }
    }
    
    func recordingButtonDidStartRecording() {
        stopPlayer()
        
        self.recordStartSound?.play()
        
        self.audioRecorder.willStartRecording {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.startRecording()
                self.recordView.show()
            }
        }

    }
    
    func handleTimerButton(_ isAuthorized: Bool) {
        if activeTools.contains(.timer) {
            unscheduleTimerNotification()
            self.timerView.stopTimer()
            self.toggleToolButton(self.timerButton)
        }
        else {
            let alert = TimerPickerAlertController()

            alert.action = {
                [weak self] duration in
                guard let self = self else { return }
                
                self.timerView.startTimer(duration)
                Settings.practiceTimerMinutes = Int(duration / 60)
                self.toggleToolButton(self.timerButton)
                
                if isAuthorized {
                    self.scheduleTimerNotification(duration: duration)
                }

            }

            self.presentAlert(alert, sourceView: timerButton, arrowDirection: .down)
            
        }
        
    }
    
}

//MARK: - Tuner tool
extension PracticeViewController {
    
    func openTuner() {
        
        if Settings.isPremium || allowTuner {
            let vc = TunerViewController()
            self.tunerViewController = vc
            self.presentAlert(vc, sourceView: tunerButton, arrowDirection: .down)
        }
        else {
            if !Settings.didTryTuner {
                let alert = AreYouSureAlert(
                    isDistructive: false,
                    title: "Drone Tuner", description: "The Drone Tuner is a Pro feature, but you can try it out during one session before needing to purchase Andante Pro! Try it now?", destructiveText: "Try now", cancelText: "Cancel") {
                    
                    [weak self] in
                    guard let self = self else { return }
                    
                    Settings.didTryTuner = true
                    self.allowTuner = true
                    let vc = TunerViewController()
                    self.tunerViewController = vc
                    self.presentAlert(vc, sourceView: self.tunerButton, arrowDirection: .down)
                    
                }
                
                self.presentAlert(alert, sourceView: tunerButton, arrowDirection: .down)
            }
            else {
                self.presentModal(AndanteProViewController(), animated: true, completion: nil)
            }
        }
        
        
    }
    
}

//MARK: - Timer Tool
extension PracticeViewController: TimerToolDelegate, UNUserNotificationCenterDelegate {
    
    private func scheduleTimerNotification(duration: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Practice Timer"
        content.subtitle = "Your timer is done!"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "timer"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
    
    func unscheduleTimerNotification() {
        var timerNotifications: [String] = []
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            requests.forEach { (request) in
                if request.content.categoryIdentifier == "timer" {
                    timerNotifications.append(request.identifier)
                }
            }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: timerNotifications)
        }
    }
    
    func timerToolDidFinish() {
        
        timerFinishedSound?.play()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        unscheduleTimerNotification()
        
        toggleToolButton(timerButton)
        
        let alert = TimerCompleteAlertController()
        (self.presentedViewController ?? self).presentAlert(alert, sourceView: timerButton, arrowDirection: .down)
        
        alert.repeatAction = {
            [weak self] in
            guard let self = self else { return }
            
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) {
                [weak self] success, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    [weak self] in
                    guard let self = self else { return }
                    
                    let duration = TimeInterval(Settings.practiceTimerMinutes * 60)
                    self.timerView.startTimer(duration)
                    self.toggleToolButton(self.timerButton)
                    
                    if success {
                        self.scheduleTimerNotification(duration: duration)
                    }
                    
                }
                
                
            }
            
        }
        
        
    }
    
}

//MARK: - Recording
extension PracticeViewController: RecordingToolViewDelegate {

    func recordingViewDidTapDelete() {
        let alert = AreYouSureAlert(title: "Delete recording?", description: "Your recording will be permanently deleted.", destructiveText: "Delete Recording", cancelText: "Cancel") {
            [weak self] in
            guard let self = self else { return }
            self.deleteRecording()
        }
        self.presentAlert(
            alert,
            sourceView: recordView.deleteButton,
            sourceRect: recordView.deleteButtonSourceRect,
            arrowDirection: .down)
    }
    
    func deleteRecording() {
        self.recordView.delete()
        
        do {
            for recording in recordingChunks {
                try FileManager.default.removeItem(at: recording.url)
            }
        }
        catch {
            print(error)
        }
        
        recordingChunks.removeAll()
        
        CDOngoingSession.ongoingSession?.update(updates: { (session) in
            session.recordings = []
        })
        
        activeTools.remove(at: 0)
                
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.viewDidLayoutSubviews()
        }, completion: nil)
    }
    
    func checkAudioPermissions(_ completion: ((Bool)->Void)?) {
        let microphoneStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
        if microphoneStatus == .notDetermined {
            self.audioRecorder.askPermission { (granted) in
                DispatchQueue.main.async {
                    completion?(granted)
                }
            }
        }
        else if microphoneStatus == .authorized {
            completion?(true)
        }
        else {
            completion?(false)
        }
    }
    
    func audioPermissionsFailed() {
        let alert = DescriptionActionAlertController(title: "Permission Needed", description: "In order to record your session, Andante needs access to the microphone. You can allow access in your iPhone's settings.", actionText: "Open Settings", action: nil)
        alert.action = {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        }
        self.presentAlert(alert, sourceView: recordButton, arrowDirection: .down)
    }
    
    func startRecording() {
            
        self.audioRecorder.percentLoudness = { [weak self] (loud) in
            if let self = self {
                self.recordView.currentLoudness = loud
            }
        }
        
        self.audioRecorder.startRecording()
        
    }
    
    func updateRecordingPlaybackPosition() {
        if recordingChunks.count == 1 {
            recordView.setPlaybackPoint(0)
        }
        else {
            var totalTime: TimeInterval = 0
            var time: TimeInterval = 0
            for (i, asset) in recordingChunks.enumerated() {
                totalTime += asset.duration.seconds
                if i != recordingChunks.count-1 {
                    time += asset.duration.seconds
                }
            }
            if totalTime != 0 {
                recordView.setPlaybackPoint(CGFloat(time / totalTime))
            }
        }
        
    }
    
    func stopRecording() {
        
        guard let url = audioRecorder.audioFilename else {
            return
        }
        
        self.audioRecorder.endRecording()
        
        let assetOpts = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        let asset     = AVURLAsset(url: url, options: assetOpts)

        self.recordingChunks.append(asset)
        self.updateRecordingPlaybackPosition()
        
        CDOngoingSession.ongoingSession?.update(updates: { (session) in
            var recordings = session.recordings
            recordings.append(RecordingsManager.filename(from: asset.url))
            session.recordings = recordings
        })
        
        audioRecorder.prepare()
        
    }
    
}

//MARK: - Playback
extension PracticeViewController {
    
    func startAudioPlayer(at time: TimeInterval) {

        let assetKeys = ["playable"]
        let playerItems = self.recordingChunks.map {
            AVPlayerItem(asset: $0, automaticallyLoadedAssetKeys: assetKeys)
        }

        self.queuePlayer = AVQueuePlayer(items: playerItems)
        self.queuePlayer?.actionAtItemEnd = .advance
                
        var actualTime: TimeInterval = time
        for item in recordingChunks {
            
            let itemSeconds = item.duration.seconds
            if itemSeconds < actualTime {
                actualTime -= itemSeconds
                queuePlayer?.advanceToNextItem()
            }
            else {
                break
            }
        }
        
        self.queuePlayer?.seek(to: CMTime(seconds: actualTime, preferredTimescale: 1000000))
        self.queuePlayer?.play()

    }
    
    func stopPlayer() {
        self.queuePlayer?.pause()
        self.queuePlayer = nil
    }
    
    func recordingViewDidTapPlay(at time: TimeInterval) {
        startAudioPlayer(at: time)
    }
    
    func recordingViewDidTapPause() {
        stopPlayer()
    }
    
    func currentPlaybackTime() -> TimeInterval {
        if let time = self.queuePlayer?.currentTime(), let item = self.queuePlayer?.currentItem {
            let elapsedTime = queueDurationUntil(item: item)
            let currentTime = max(0, time.seconds)

            return elapsedTime + currentTime
        }
            
        return 0
    }
    
    func currentAudioTime() -> TimeInterval {
        var time = self.audioRecorder.audioRecorder?.currentTime ?? 0
        for asset in self.recordingChunks {
            time += asset.duration.seconds
        }
        return time
    }
    
    private func totalQueueDuration() -> TimeInterval {
        var time: TimeInterval = 0
        for item in recordingChunks {
            time += item.duration.seconds
        }
        return time
    }
    
    private func queueDurationUntil(item: AVPlayerItem) -> TimeInterval {
        guard let queuePlayer = self.queuePlayer else { return 0 }
        
        var time: TimeInterval = 0
        
        //the items in the queue, including the current item, excluding previous items
        let itemCount = queuePlayer.items().count
        let totalItems = self.recordingChunks.count
        
        let elapsedItemCount = totalItems - itemCount
        
        if elapsedItemCount == 0 { return 0 }
        
        for i in 0..<elapsedItemCount {
            let elapsedItem = self.recordingChunks[i]
            time += elapsedItem.duration.seconds
        }
        
        return time
        
    }
    
    
}


//MARK: Audio handling
extension PracticeViewController: AudioNotificationHandlerDelegate {
    
    func audioInterruptionDidBegin() {
        
        audioNotifictionHandler.audioInterruptionDidEndHandler = nil
        
        var endHandlers: [(()->Void)?] = []
        
        if recordView.isRecording {
            stopRecording()
            recordView.hide()
            recordButton.setState(.inactive)
        }
        else if recordView.isPlayingAudio {
            recordView.pauseAudio()
            
            endHandlers.append {
                [weak self] in
                guard let self = self else { return }
                self.recordView.playAudio()
            }
            
        }
       
        if let tuner = tunerViewController {
            if tuner.isPlaying {
                tuner.stop()
                endHandlers.append {
                    [weak self] in
                    guard let self = self else { return }
                    self.tunerViewController?.start()
                }
                
            }
        }
        
        if activeTools.contains(.metronome) {
            didTapToolButton(metronomeButton)
        }
        
        audioNotifictionHandler.audioInterruptionDidEndHandler = {
            for handler in endHandlers {
                handler?()
            }
        }
        
    }
    
    func audioRouteOldDeviceUnavailable() {
        audioNotifictionHandler.audioRouteNewDeviceAvailable = nil
        
        if recordView.isPlayingAudio {
            recordView.pauseAudio()
            audioNotifictionHandler.audioRouteNewDeviceAvailable = {
                [weak self] in
                guard let self = self else { return }
                
                self.recordView.playAudio()
            }
        }
    }
    
}

//MARK: Saving
extension PracticeViewController {
    public func saveSession(dismiss: Bool = true) {
        
        saveRecording(session)
        
        if session.title == "" {
            session.title = User.getActiveProfile()?.defaultSessionTitle ?? "Practice"
        }
        
        if let container = self.presentingViewController as? AndanteViewController {
            container.savePracticeSession(session)
        }
        self.cleanup(save: true)
        
        if dismiss {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    private func saveRecording(_ session: SessionModel) {
        for chunk in recordingChunks {
            do {
                
                let data = try Data(contentsOf: chunk.url)
                session.recordings.append(data)
                
                try FileManager.default.removeItem(at: chunk.url)
                
            }
            catch {
                print(error)
            }

        }
    }
}

protocol AudioNotificationHandlerDelegate: AnyObject {
    
    func audioInterruptionDidBegin()
    
    func audioRouteOldDeviceUnavailable()
        
}

class AudioNotificationHandler: NSObject {
    
    public weak var delegate: AudioNotificationHandlerDelegate?
    
    public var audioInterruptionDidEndHandler: (()->Void)?
    public var audioRouteNewDeviceAvailable: (()->Void)?
        
    override init() {
        super.init()
        
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
    
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }

        if type == .began {
            self.delegate?.audioInterruptionDidBegin()
        }
        else if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    audioInterruptionDidEndHandler?()
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
            self.delegate?.audioRouteOldDeviceUnavailable()
        }
        else if reason == .newDeviceAvailable {
            self.audioRouteNewDeviceAvailable?()
        }
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

extension AVMutableCompositionTrack {
    func append(url: URL) {
        let newAsset = AVURLAsset(url: url)
        let range = CMTimeRangeMake(start: CMTime.zero, duration: newAsset.duration)
        let end = timeRange.end
        
        if let track = newAsset.tracks(withMediaType: AVMediaType.audio).first {
            try! insertTimeRange(range, of: track, at: end)
        }
        
    }
}

func mergeAudio(_ url1: URL, _ url2: URL, outputURL: URL, completion: ((Bool)->Void)?) {
    let composition = AVMutableComposition()
    let compositionAudioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)

    compositionAudioTrack?.append(url: url1)
    compositionAudioTrack?.append(url: url2)

    if let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) {
        assetExport.outputFileType = AVFileType.m4a
        assetExport.outputURL = outputURL
        assetExport.exportAsynchronously {
            switch assetExport.status {
            case .failed:
                print(assetExport.error)
                completion?(false)
            default:
                completion?(true)
            }
        }
    }
}

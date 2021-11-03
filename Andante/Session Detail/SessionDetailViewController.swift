//
//  SessionDetailViewController.swift
//  Andante
//
//  Created by Miles Vinson on 7/27/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import UIKit
import AVKit
import Combine

class CancelTouchScrollView: UIScrollView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.canCancelContentTouches = true
        self.delaysContentTouches = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesShouldCancel(in view: UIView) -> Bool {
        return true
    }
}

class SessionDetailViewController: TransitionViewController, UITextViewDelegate {
    
    private let topView = Separator()
    private var backButton: Button!
    private var optionsButton: Button!
    private var headerView = UIView()
    
    public let session: CDSession
    public let indexPath: IndexPath?
    
    private let titleLabel = UITextField()
    private let dateLabel = UILabel()
    private let notesLabel = UILabel()
    
    private let scrollView = ScrollView()
    private let textView = SessionNotesTextView()
    
    private let profileCell = SessionProfileCell()
    private let timeCell = SessionStatsCell()
    private let practicedCell = SessionStatsCell()
    private let moodCell = SessionStatsCell()
    private let focusCell = SessionStatsCell()
    
    private var recordingView: RecordingPlayerView?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(session: CDSession, indexPath: IndexPath?) {
        self.session = session
        self.indexPath = indexPath
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Colors.foregroundColor
        self.preferredContentSize = Constants.modalSize
        
        scrollView.backgroundColor = Colors.foregroundColor
        scrollView.delegate = self
        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = true
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        self.view.addSubview(scrollView)
        
        textView.font = Fonts.regular.withSize(17)
        textView.textColor = Colors.text.withAlphaComponent(0.9)
        textView.backgroundColor = .clear
        textView.placeholder = "Tap to add a note for this session"
        textView.isScrollEnabled = false
        scrollView.addSubview(textView)
        
        textView.shouldStartEditingHandler = {
            [weak self] in
            guard let self = self else { return false }
            
            if Settings.isPremium {
                return true
            }
            else {
                self.presentModal(AndanteProViewController(), animated: true, completion: nil)
                return false
            }
        }
        
        session.objectWillChange.sink {
            [weak self] in
            guard let self = self else { return }
            if self.session.isDeleted {
                if let presented = self.presentedViewController {
                    presented.dismiss(animated: false, completion: nil)
                }
                self.close()
            }
            else {
                self.updateAttributes()
            }
        }.store(in: &cancellables)
                
        titleLabel.tintColor = Colors.orange
        titleLabel.text = session.getTitle()
        titleLabel.font = Fonts.bold.withSize(30)
        titleLabel.placeholder = "Practice"
        titleLabel.textColor = Colors.text
        titleLabel.autocapitalizationType = .words
        titleLabel.delegate = self
        titleLabel.returnKeyType = .done
        scrollView.addSubview(titleLabel)
        
        notesLabel.textColor = Colors.text
        notesLabel.font = Fonts.semibold.withSize(20)
        notesLabel.text = "Notes"
        scrollView.addSubview(notesLabel)
        
        dateLabel.font = Fonts.medium.withSize(20)
        dateLabel.textColor = Colors.lightText
        dateLabel.text = session.startTime.string(dateStyle: .long)
        scrollView.addSubview(dateLabel)
                
        textView.text = session.notes ?? ""
        
        let doneToolbar = DoneToolbar()
        doneToolbar.doneHandler = {
            [weak self] in
            self?.textView.resignFirstResponder()
        }
        textView.inputAccessoryView = doneToolbar
        textView.delegate = self
                
        if session.hasRecording {
            recordingView = RecordingPlayerView(recordings: session.getRecordings())
            scrollView.addSubview(recordingView!)
        }
        
        scrollView.addSubview(profileCell)
        scrollView.addSubview(timeCell)
        scrollView.addSubview(practicedCell)
        scrollView.addSubview(moodCell)
        scrollView.addSubview(focusCell)
        
        setStats()
        
        topView.color = Colors.barSeparator
        topView.position = .bottom
        topView.insetToMargins()
        topView.alpha = 0
        self.view.addSubview(topView)
        
        backButton = Button("chevron.left")
        backButton.contentHorizontalAlignment = .left
        backButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.textView.resignFirstResponder()
            self.close()
        }
        headerView.addSubview(backButton)
        
        optionsButton = Button("ellipsis")
        optionsButton.contentHorizontalAlignment = .right
        optionsButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.titleLabel.resignFirstResponder()
            self.textView.resignFirstResponder()
            self.openOptionsMenu()
        }
        headerView.addSubview(optionsButton)
        
        view.addSubview(headerView)
        
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
                
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        textView.resignFirstResponder()
        titleLabel.resignFirstResponder()
        
    }
        
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        recordingView?.stopAudio()
        
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            self.scrollView.contentInset.bottom = 0
            scrollView.scrollIndicatorInsets = UIEdgeInsets(t: 0, b: view.safeAreaInsets.bottom)
        } else {
            UIView.animate(withDuration: 0.25) {
                self.scrollView.contentInset.bottom = keyboardViewEndFrame.height
                
                if self.titleLabel.isFirstResponder {
                    self.scrollView.setContentOffset(.init(x: 0, y: -self.scrollView.contentInset.top), animated: false)
                }
            }
            
            scrollView.scrollIndicatorInsets = UIEdgeInsets(t: 0, b: keyboardViewEndFrame.height)
            
        }
    }
    
    private func setStats() {
        profileCell.profile = self.session.profile
        
        timeCell.setTimeTitle(start: session.startTime, end: session.getEndTime())
        timeCell.iconView.stat = .time
        
        practicedCell.setTitle(Formatter.formatMinutes(mins: session.practiceTime), " practiced")
        practicedCell.iconView.stat = .practice
        
        moodCell.setTitle("\(session.mood)", " / 5 mood")
        moodCell.iconView.stat = .mood
        moodCell.iconView.value = session.mood
        
        focusCell.setTitle("\(session.focus)", " / 5 focus")
        focusCell.iconView.stat = .focus
        focusCell.iconView.value = session.focus
        
        recordingView?.sessionTitle = session.getTitle()

    }
    
    private func updateAttributes() {
        
        guard session.isDeleted == false else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        timeCell.setTimeTitle(start: session.startTime, end: session.getEndTime())
        practicedCell.setTitle(Formatter.formatMinutes(mins: session.practiceTime), " practiced")
        moodCell.setTitle("\(session.mood)", " / 5 mood")
        moodCell.iconView.value = session.mood
        focusCell.setTitle("\(session.focus)", " / 5 focus")
        focusCell.iconView.value = session.focus
        titleLabel.text = session.getTitle()
        textView.text = session.notes ?? ""
        dateLabel.text = session.startTime.string(dateStyle: .long)
        recordingView?.sessionTitle = session.getTitle()
        view.setNeedsLayout()
    }
    
    func scrollTextView() {
        layoutTextView()
        
        let selectionFrame = textView.convert(textView.currentSelectionRect, to: scrollView)
        let maxOffset = scrollView.contentSize.height - self.scrollView.bounds.height + scrollView.contentInset.bottom
        
        UIView.animateWithCurve(duration: 0.4, curve: UIView.CustomAnimationCurve.cubic.easeOut, animation: {
            self.scrollView.setContentOffset(
                CGPoint(x: 0, y: min(maxOffset, selectionFrame.origin.y - self.view.safeAreaInsets.top - self.view.bounds.height*0.15)),
                animated: false)
        }, completion: nil)

        
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if textView.isFirstResponder {
            scrollTextView()
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        layoutTextView()
        scrollTextView()
    }
    
    override func viewDidBeginDragging() {
        super.viewDidBeginDragging()
        textView.resignFirstResponder()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        session.notes = self.textView.text
        DataManager.saveContext()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y + scrollView.contentInset.top
        topView.alpha = (offset - 20)/20
    }
    
    @objc func openOptionsMenu() {
        let optionsView = SessionOptionsPopupStackView(session: self.session)
        let popupVC = PopupStackViewController(optionsView)
        self.presentPopupViewController(popupVC)
        
        return
        let optionsVC = SessionOptionsPopupController()
        optionsVC.session = self.session
        
        optionsVC.sourceView = optionsButton
        
        optionsVC.deleteHandler = {
            [weak self] in
            guard let self = self else { return }
            DataManager.context.delete(self.session)
            DataManager.saveContext()
        }
        
        optionsVC.editHandler = {
            [weak self] in
            guard let self = self else { return }
            self.handleEdits()
        }
        
        optionsVC.moveHandler = {
            [weak self] profile  in
            guard let self = self else { return }
            
            let attributes = CDSessionAttributes(context: DataManager.context)
            attributes.focus = Int64(self.session.focus)
            attributes.mood = Int64(self.session.mood)
            attributes.practiceTime = Int64(self.session.practiceTime)
            attributes.startTime = self.session.startTime
            
            if let currentAttributes = self.session.attributes {
                DataManager.context.delete(currentAttributes)
                self.session.attributes = nil
            }
            
            self.session.profile?.removeFromSessions(self.session)
            
            self.session.attributes = attributes
            profile.addToSessions(self.session)
            
            DataManager.saveContext()
            
            self.close()
        }
        
        optionsVC.shareHandler = {
            [weak self] shareOptions in
            guard let self = self else { return }
            self.handleShare(shareOptions)
        }
        
        self.presentPopupViewController(optionsVC)
    }
    
    private func handleShare(_ options: Set<SessionOptionsPopupController.ShareType>) {
        
        var activityItems: [Any] = []
        
        
        if options.contains(.notes) {
            if let url = getNotesFile() {
                activityItems.append(url)
            }
        }
        
        if options.contains(.session) {
            if let url = getImageURL() {
                activityItems.append(url)
            }
        }
        
        if options.contains(.recording) {
            getShareableRecording {
                [weak self] (url) in
                guard let self = self else { return }
                
                if let url = url {
                    activityItems.insert(url, at: 0)
                    
                    let ac = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                    ac.popoverPresentationController?.sourceView = self.optionsButton
                    ac.popoverPresentationController?.sourceRect = self.optionsButton.imageView!.frame.offsetBy(dx: 0, dy: 8)
                    
                    ac.completionWithItemsHandler = { (type, completed, items, error) in
                        try? FileManager.default.removeItem(at: url)
                    }
                    
                    self.presentModal(ac, animated: true, completion: nil)
                }
                
            }
        }
        else {
            let ac = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            ac.popoverPresentationController?.sourceView = optionsButton
            ac.popoverPresentationController?.sourceRect = self.optionsButton.imageView!.frame.offsetBy(dx: 0, dy: 8)
            
            ac.completionWithItemsHandler = { (type, completed, items, error) in
                
                for item in activityItems {
                    if let url = item as? URL {
                        try? FileManager.default.removeItem(at: url)
                    }
                }
            }
            
            self.presentModal(ac, animated: true, completion: nil)
        }
        
        
    }
    
    private func getNotesFile() -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(session.getTitle()) Notes.txt")
        do {
            try (session.notes ?? "").write(to: url, atomically: false, encoding: .utf8)
            return url
        }
        catch {
            print("Error writing notes to txt file:", error)
            return nil
        }
    }
    
    private func handleEdits() {
        let editController = EditSessionViewController(self.session)
        
        editController.saveHandler = {
            [weak self] edits in
            guard let self = self else { return }
            
            self.updateSessionEdits(edits)
            
        }
        
        self.presentModal(editController, animated: true, completion: nil)

    }
    
    private func updateSessionEdits(_ edits: EditSessionViewController.SessionEdits) {
        
        let sessionID = self.session.objectID
        
        let context = DataManager.backgroundContext
        if let session = try? context.existingObject(with: sessionID) as? CDSession {
            session.title = edits.title
            session.notes = edits.notes
            session.startTime = edits.begin
            session.mood = edits.mood
            session.focus = edits.focus
            session.practiceTime = edits.practiceTime
            session.end = edits.begin.addingTimeInterval(TimeInterval(edits.practiceTime*60))
            
            try? context.save()
        }
    }
    
    deinit {
        print("deinit")
    }
    
    
    //MARK: viewDidLayoutSubviews
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let margin = Constants.margin
        let textWidth: CGFloat = min(view.bounds.width, 800)
        let textMargin = (view.bounds.width - textWidth)/2 + margin
        
        headerView.frame = CGRect(
            x: 0, y: view.safeAreaInsets.top,
            width: view.bounds.width, height: 44)
        
        topView.frame = CGRect(
            x: 0, y: 0,
            width: self.view.bounds.width,
            height: 44 + self.view.safeAreaInsets.top)
        
        backButton.contentEdgeInsets.left = margin - 1
        backButton.frame = CGRect(
            x: 0, y: 0,
            width: margin + 56, height: 44)
        
        optionsButton.contentEdgeInsets.right = margin
        optionsButton.frame = CGRect(
            x: view.bounds.maxX - (margin+56), y: 0,
            width: margin + 56, height: 44)
        
        scrollView.frame = self.view.bounds.inset(by: UIEdgeInsets(t: headerView.frame.maxY))
        let bottomInset = scrollView.contentInset.bottom != 0 ? scrollView.contentInset.bottom : view.safeAreaInsets.bottom
        scrollView.scrollIndicatorInsets = UIEdgeInsets(t: 0, b: bottomInset)
        
        layoutTitleLabel()
        
        layoutRecordingView()
                  
        layoutStats()
        
        notesLabel.sizeToFit()
        notesLabel.frame.origin = CGPoint(
            x: textMargin,
            y: focusCell.frame.maxY + 22)
        
        layoutTextView()
        
        
    }
    
    private func layoutTextView() {
        
        let margin = Constants.margin
        let textWidth: CGFloat = min(view.bounds.width, 800)
        let textMargin = (view.bounds.width - textWidth)/2 + margin
        
        textView.textContainerInset = UIEdgeInsets(top: 0, left: textMargin - 4, bottom: 50, right: textMargin - 4)
        
        let textHeight = textView.sizeThatFits(self.view.bounds.size).height
        let height = textView.isFirstResponder ? max(textHeight, self.view.bounds.height*0.4) : textHeight
        
        textView.frame = CGRect(
            x: 0, y: notesLabel.frame.maxY + 8,
            width: scrollView.bounds.width,
            height: height)
        
        scrollView.contentSize = CGSize(
            width: self.view.bounds.width,
            height: textView.frame.maxY)
    }
    
    private func layoutRecordingView() {
        let totalWidth: CGFloat = min(view.bounds.width, 800)
        let margin = (view.bounds.width - totalWidth)/2 + Constants.margin
        let width = view.bounds.width - margin*2
        
        recordingView?.frame = CGRect(
            x: margin, y: dateLabel.frame.maxY + 6,
            width: width,
            height: 120)
    }
    
    private func layoutStats() {
        
        let statsMinY = recordingView == nil ? (dateLabel.frame.maxY + 16) : (dateLabel.frame.maxY + 16 + 120)
        
        let cellHeight: CGFloat = 64
        
        let totalWidth: CGFloat = min(view.bounds.width, 800)
        let margin = (view.bounds.width - totalWidth)/2 + Constants.margin
        let width = totalWidth - margin*2
        
        profileCell.frame = CGRect(
            x: margin, y: statsMinY,
            width: width,
            height: cellHeight)
        
        timeCell.frame = CGRect(
            x: margin, y: profileCell.frame.maxY,
            width: width,
            height: cellHeight)
        
        practicedCell.frame = CGRect(
            x: margin, y: timeCell.frame.maxY,
            width: width,
            height: cellHeight)
        
        moodCell.frame = CGRect(
            x: margin, y: practicedCell.frame.maxY,
            width: width,
            height: cellHeight)
        
        focusCell.frame = CGRect(
            x: margin, y: moodCell.frame.maxY,
            width: width,
            height: cellHeight)
        
    }
    
    private func layoutTitleLabel() {
        let totalWidth: CGFloat = min(view.bounds.width, 800)
        let margin = (view.bounds.width - totalWidth)/2 + Constants.margin
        let width = totalWidth - margin*2
        
        titleLabel.sizeToFit()
        
        let titleWidth: CGFloat
        if titleLabel.isFirstResponder {
            titleWidth = width
        } else {
            titleWidth = min(titleLabel.bounds.width, width)
        }
        
        titleLabel.frame = CGRect(x: margin, y: 36,
                                  width: titleWidth,
                                  height: titleLabel.bounds.size.height)
        
        dateLabel.sizeToFit()
        dateLabel.frame.origin = CGPoint(x: margin, y: titleLabel.frame.maxY + 4)
        
    }
    
}

//MARK: Textfield delegate
extension SessionDetailViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        layoutTitleLabel()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        layoutTitleLabel()
        
        if textField.hasText {
            session.title = textField.text ?? session.title
        }
        else {
            session.title = session.profile?.defaultSessionTitle ?? "Practice"
        }
        
        DataManager.saveContext()
        
    }
    
}

//MARK: Share
extension SessionDetailViewController {
    
    func getImageURL() -> URL? {
        
        let imgView = SessionShareView(session: session)
        imgView.layoutSubviews()
        
        UIGraphicsBeginImageContextWithOptions(imgView.bounds.size, false, UIScreen.main.scale)
        imgView.drawHierarchy(in: imgView.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if image == nil { return nil }
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(session.getTitle()).png")
        
        do {
            try image!.pngData()?.write(to: url, options: .atomic)
            return url
        }
        catch {
            return nil
        }
        
    }


    func getDocumentDirectoryPath(fileName:String) -> NSURL {
        let paths:NSArray = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let docuementDir:NSString = paths.object(at: 0) as! NSString
        return NSURL.fileURL(withPath: docuementDir.appendingPathComponent(fileName)) as NSURL
    }
    
    private func getShareableRecording(_ completion: ((URL?)->())?) {
        let alert = CenterLoadingViewController(style: .progress)
        alert.text = "Preparing your recording"

        self.present(alert, animated: false, completion: nil)

        let composition = AVMutableComposition()

        var insertAt = CMTimeRange(start: CMTime.zero, end: CMTime.zero)

        let assetOpts = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        var recordingChunks: [AVURLAsset] = []
        
        let directory = FileManager.default.temporaryDirectory
        for recording in session.getRecordings() {
            let filename = "\(UUID().uuidString).m4a"
            let url = directory.appendingPathComponent(filename)
            do {
                try recording.recordingData?.write(to: url)
                let asset = AVURLAsset(url: url, options: assetOpts)
                recordingChunks.append(asset)
            } catch {
                print(error)
            }
        }
        
        for asset in recordingChunks {
            let assetTimeRange = CMTimeRange(
            start: CMTime.zero, end: asset.duration)

            do {
                try composition.insertTimeRange(assetTimeRange,
                                                of: asset,
                                                at: insertAt.end)
            } catch {
                NSLog("Unable to compose asset track.")
            }

            let nextDuration = insertAt.duration + assetTimeRange.duration
            insertAt = CMTimeRange(start: CMTime.zero,
                                      duration: nextDuration)
        }

        let exportSession =
            AVAssetExportSession(
                asset:      composition,
                presetName: AVAssetExportPresetAppleM4A)

        let date = session.startTime
        let dateStr = date.string(dateStyle: .short).replacingOccurrences(of: "/", with: "-")

        let filename = "\(session.getTitle()) \(dateStr) \(date.string(timeStyle: .medium)).m4a"

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        //delete existing file if necessary (edge case for sure)
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print(error)
        }

        exportSession?.outputFileType = AVFileType.m4a
        exportSession?.outputURL = url

        exportSession?.canPerformMultiplePassesOverSourceMediaData = true

        let timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { (timer) in
            alert.progress = exportSession?.progress ?? 0
        }
        
        exportSession?.exportAsynchronously {
            switch exportSession?.status {
            case .completed:
                DispatchQueue.main.async {
                    [weak self] in
                    guard let self = self else { return }

                    timer.invalidate()
                    
                    alert.closeAction = {
                        [weak self] in
                        guard let self = self else { return }

                        completion?(url)
                    }

                    alert.close()
                    

                }
            default:
                print("something went wrong")
            }
            
            for chunk in recordingChunks {
                do {
                    try FileManager.default.removeItem(at: chunk.url)
                    print("deleted")
                } catch {
                    print("Error deleting generated file: \(error)")
                }
            }
        }
        
        
    }
    
}





class SessionStatsCell: UIView {
    
    public let iconView = StatIconView()
    private let titleLabel = UILabel()
    
    public var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    public func setTitle(_ part1: String, _ part2: String) {
        let str = NSMutableAttributedString(string: part1, attributes: [
            NSAttributedString.Key.foregroundColor : Colors.text,
            NSAttributedString.Key.font : Fonts.semibold.withSize(17),
            .kern : 0//.6
        ])
        
        str.append(NSAttributedString(string: part2, attributes: [
            NSAttributedString.Key.foregroundColor : Colors.lightText,
            NSAttributedString.Key.font : Fonts.regular.withSize(17),
            .kern : 0//.6
        ]))
        
        titleLabel.attributedText = str
        setNeedsLayout()
    }
    
    public func setTimeTitle(start: Date, end: Date) {
        self.setTitle(start.string(timeStyle: .short), " - " + end.string(timeStyle: .short))
    }
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = .clear
        
        self.addSubview(iconView)
        
        titleLabel.font = Fonts.regular.withSize(19)
        titleLabel.textColor = Colors.text
        self.addSubview(titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        iconView.iconSize = CGSize(22)
        iconView.frame = CGRect(
            x: 0,
            y: self.bounds.midY - 18,
            width: 38,
            height: 38).integral
        iconView.roundCorners(10)
        
        titleLabel.sizeToFit()
        titleLabel.frame = CGRect(x: iconView.frame.maxX + 16, y: 0,
                                  width: titleLabel.bounds.width,
                                  height: self.bounds.height)
    }
}

class SessionProfileCell: UIView {
    
    public let iconView = ProfileImageView()
    private let titleLabel = UILabel()
    
    private var cancellables = Set<AnyCancellable>()
    
    public var profile: CDProfile? {
        didSet {
            self.cancellables.removeAll()
            
            self.profile?.publisher(for: \.name).sink { [weak self] name in
                self?.titleLabel.text = name
            }.store(in: &cancellables)
            
            self.iconView.profile = self.profile
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = .clear
        
        iconView.inset = 6
        iconView.cornerRadius = 10
        self.addSubview(iconView)
        
        titleLabel.font = Fonts.semibold.withSize(17)
        titleLabel.textColor = Colors.text
        self.addSubview(titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        iconView.frame = CGRect(
            x: 0,
            y: self.bounds.midY - 18,
            width: 38,
            height: 38).integral
        
        titleLabel.sizeToFit()
        titleLabel.frame = CGRect(x: iconView.frame.maxX + 16, y: 0,
                                  width: titleLabel.bounds.width,
                                  height: self.bounds.height)
    }
}


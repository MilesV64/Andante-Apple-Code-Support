//
//  EntryViewController.swift
//  Andante
//
//  Created by Miles Vinson on 6/11/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit
import Combine

extension UIImage {
    func resized(toWidth width: CGFloat) -> UIImage? {
        let height = CGFloat(ceil(width / size.width * size.height))
        let canvasSize = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func rounded(_ size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size.width, height: size.height), false, scale)
        defer { UIGraphicsEndImageContext() }
        
        let imageFrame = CGRect(
            origin: CGPoint(x: 0, y: 10),
            size: CGSize(width: size.width, height: size.height-20))
        
        
        
        let path = UIBezierPath(roundedRect: imageFrame.insetBy(dx: 30, dy: 20), cornerRadius: 6)
        path.addClip()
        draw(in: imageFrame)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

class A: NSTextAttachment {
    
    let aspect: CGFloat = 2
    
    override func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
        return self.image?.rounded(imageBounds.size)
    }
    
    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        
        if let width = textContainer?.size.width {
            let w = width - 10
            return CGRect(x: 0, y: 0, width: w, height: w * aspect + 20)
        }
        else if let width = textContainer?.size.width, let image = self.image {
            let aspect = image.size.height / image.size.width
            let w = width - 10
            return CGRect(x: 0, y: 0, width: w, height: w * aspect + 20)
        }
        else {
            return super.attachmentBounds(for: textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
        }
    }
}

@objc protocol EntryViewControllerDelegate: class {
    @objc func entryViewControllerDidDissapear(_ viewController: EntryViewController, entry: CDJournalEntry?, hasText: Bool)
    @objc func entryViewControllerWillDissapear(_ viewController: EntryViewController, entry: CDJournalEntry?, attributedText: NSAttributedString)
    func entryViewControllerDidSelectDelete(entry: CDJournalEntry?)
    func entryViewControllerDidSelectMove(entry: CDJournalEntry?, to folder: CDJournalFolder)
    func entryViewControllerDidAddFolder()
}

class EntryViewController: TransitionViewController {
    
    private let interactionHaptic = UIImpactFeedbackGenerator(style: .light)
    
    public var entry: CDJournalEntry?
    public var entryCell: JournalCell?
    public var delegate: EntryViewControllerDelegate?
    
    public var lastEdit: Date?
    
    private let textView = RichTextView()
    private let toolbar = RichTextToolbar()
    
    private let topView = Separator()
    private var backButton: Button!
    private var optionsButton: Button!
        
    private var isKeyboardOpen = false
    
    private var headerView = UIView()
    
    public var hasText: Bool {
        return textView.hasText
    }
    
    public var shouldOpenKeyboard = false
    
    public var isWriting: Bool {
        return textView.isFirstResponder
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.entryViewControllerDidDissapear(self, entry: entry, hasText: textView.hasText)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(entry: CDJournalEntry?) {
        self.entry = entry
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = Colors.foregroundColor
        
        entry?.objectWillChange.sink {
            [weak self] in
            guard let self = self else { return }
            if self.entry == nil || self.entry!.isDeleted {
                self.presentedViewController?.dismiss(animated: false, completion: nil)
                self.styleMenu?.hide(animated: false, ignoreSelectedItem: true)
                
                self.close()
            } else {
                if let text = self.entry?.attributedText() {
                    self.textView.attributedText = text
                }
            }
        }.store(in: &cancellables)
        
        toolbar.styleButton.action = {
            [weak self] in
            self?.openStyleMenu()
        }
        
        toolbar.doneHandler = {
            [weak self] in
            guard let self = self else { return }
            self.textView.resignFirstResponder()
        }
        
        textView.richTextDelegate = self
        textView.alwaysBounceVertical = true
        textView.automaticallyAdjustsScrollIndicatorInsets = false
        textView.tintColor = Colors.orange
        
        textView.inputAccessoryView = toolbar
        
        textView.keyboardDismissMode = .interactive
        
        textView.attributedText = entry?.attributedText() ?? NSAttributedString()
        textView.textColor = Colors.text

        self.view.addSubview(textView)
        
        topView.backgroundColor = Colors.foregroundColor
        topView.color = Colors.barSeparator
        topView.position = .bottom
        topView.alpha = 0
        self.view.addSubview(topView)
        
        backButton = Button("chevron.left")
        backButton.contentHorizontalAlignment = .left
        backButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.didTapBack()
        }
        headerView.addSubview(backButton)
        
        optionsButton = Button("ellipsis")
        optionsButton.contentHorizontalAlignment = .right
        optionsButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.presentOptions()
        }
        headerView.addSubview(optionsButton)
        
        view.addSubview(headerView)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(willExit), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(willExit), name: UIApplication.willTerminateNotification, object: nil)

    }
    
    
    @objc func willExit() {
        entry?.saveAttrText(textView.textStorage)
        DataManager.saveContext()
    }
            
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            self.textView.contentInset.bottom = 0
            textView.scrollIndicatorInsets = UIEdgeInsets(t: 0, b: view.safeAreaInsets.bottom)
        } else {
            UIView.animate(withDuration: 0.25) {
                self.textView.contentInset.bottom = keyboardViewEndFrame.height
            }
            textView.scrollIndicatorInsets = UIEdgeInsets(t: 0, b: self.textView.contentInset.bottom)
        }
        
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let margin = Constants.margin
        
        let textWidth: CGFloat = min(view.bounds.width, 800)
        let textMargin = (view.bounds.width - textWidth)/2 + (margin - 4)
        
        textView.textContainerInset = UIEdgeInsets(
            top: 32,
            left: textMargin,
            bottom: 20,
            right: textMargin)
        
        topView.frame = CGRect(
            x: 0, y: 0,
            width: self.view.bounds.width,
            height: 44 + self.view.safeAreaInsets.top)
        
        topView.color = Colors.barSeparator
                
        textView.textContainerInset.top = 32
        textView.textContainerInset.bottom = 32
        
        headerView.frame = CGRect(
            x: 0, y: view.safeAreaInsets.top,
            width: view.bounds.width, height: 44)
        
        textView.frame = CGRect(
            from: CGPoint(x: 0, y: topView.frame.maxY),
            to: CGPoint(x: self.view.bounds.maxX, y: view.bounds.maxY))
        let bottomInset = textView.contentInset.bottom != 0 ? textView.contentInset.bottom : view.safeAreaInsets.bottom
        textView.scrollIndicatorInsets = UIEdgeInsets(t: 0, b: bottomInset)
                
        backButton.contentEdgeInsets.left = margin - 1
        backButton.frame = CGRect(
            x: 0, y: 0,
            width: margin + 56, height: 44)
        
        optionsButton.contentEdgeInsets.right = margin
        optionsButton.frame = CGRect(
            x: view.bounds.maxX - (margin+56), y: 0,
            width: margin + 56, height: 44)
        
        
        
    }
    
    private func presentOptions() {
        //avoid editing editDate unless necessary
        if let lastEdit = lastEdit {
            entry?.saveAttrText(textView.textStorage)
        }
        
        textView.resignFirstResponder()
        
        let optionsVC = JournalEntryOptionsViewController(entry: self.entry)
        optionsVC.sourceView = optionsButton
        
        optionsVC.shareHandler = {
            [weak self] in
            guard let self = self else { return }
    
            let text = self.textView.attributedText.string
            let ac = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            ac.popoverPresentationController?.sourceView = self.optionsButton
            ac.popoverPresentationController?.sourceRect = self.optionsButton.imageView!.frame.offsetBy(dx: 0, dy: 8)
            self.present(ac, animated: true)
        }
        
        optionsVC.newFolderHandler = {
            [weak self] in
            guard let self = self else { return }
            let newFolderVC = NewFolderCenterAlertController(animateWithKeyboard: true)
            newFolderVC.confirmAction = {
                [weak self] in
                guard let self = self else { return }
                
                guard
                    let profile = User.getActiveProfile(),
                    let title = newFolderVC.textField.text
                else { return }
                
                let folder = CDJournalFolder(context: DataManager.context)
                DataManager.obtainPermanentID(for: folder)
                folder.title = title
                profile.addJournalFolder(folder)
                
                self.moveEntry(folder)
                            
            }
            
            self.present(newFolderVC, animated: false, completion: nil)
        }
        
        optionsVC.moveHandler = {
            [weak self] folder in
            guard let self = self else { return }
            self.moveEntry(folder)
        }
        
        optionsVC.askForDeletePredicate = {
            [weak self] in
            guard let self = self else { return false }
            return self.textView.text.isEmpty == false
        }
        
        optionsVC.deleteHandler = {
            [weak self] in
            guard let self = self else { return }
            self.delegate?.entryViewControllerDidSelectDelete(entry: self.entry)
            self.entry = nil
            self.textView.resignFirstResponder()
        }
        
        self.presentPopupViewController(optionsVC)
    }
    
    private func moveEntry(_ folder: CDJournalFolder) {
        guard let entry = self.entry else { return }
        
        entry.folder?.removeFromEntries(entry)
        
        var newFolderEntries = folder.getEntries()
        newFolderEntries.insert(entry, at: 0)
        folder.addToEntries(entry)
        folder.updateEntryOrder(toMatch: newFolderEntries)
        
        DataManager.saveContext()
        
        self.close()
        
    }
    
    @objc func didTapBack() {
        textView.resignFirstResponder()
        delegate?.entryViewControllerWillDissapear(self, entry: entry, attributedText: textView.textStorage)
        self.close()
    }
    
    public var firstOpen = true
    override func didAppear() {
        
        if firstOpen && shouldOpenKeyboard {
            textView.becomeFirstResponder()
        }
        
        firstOpen = false
        
        interactionHaptic.prepare()
    }
    
    override func willAppear() {
        if isKeyboardOpen {
            textView.becomeFirstResponder()
        }
    }
    
    override func viewDidBeginDragging() {
        isKeyboardOpen = textView.isFirstResponder
        textView.resignFirstResponder()
        
        delegate?.entryViewControllerWillDissapear(self, entry: entry, attributedText: textView.textStorage)
    }
    
    private weak var styleMenu: PopupMenuViewController?
    private func openStyleMenu() {
        interactionHaptic.impactOccurred()
        
        let frame = toolbar.convert(toolbar.contentView.frame, to: self.view.window)
        let menu = PopupMenuViewController()
        self.styleMenu = menu
        menu.forceAbove = true
        menu.forceLeft = true
        menu.delayCompletion = false
        menu.relativePoint = CGPoint(x: frame.minX + 48, y: frame.minY + 24)
        menu.minXConstraint = frame.minX + Constants.smallMargin/2
                
        menu.addItem(title: "Title", icon: nil, handler: {
            [weak self] in
            menu.selectItem(at: 0)
            self?.textView.setStyle(.title)
            self?.richTextViewDidChangeText()
        })
        
        menu.addItem(title: "Header", icon: nil, handler: {
            [weak self] in
            menu.selectItem(at: 1)
            self?.textView.setStyle(.header)
            self?.richTextViewDidChangeText()
        })
        
        menu.addItem(title: "Body", icon: nil, handler: {
            [weak self] in
            menu.selectItem(at: 2)
            self?.textView.setStyle(.body)
            self?.richTextViewDidChangeText()
        })
        
        switch textView.currentStyle {
        case .title: menu.selectItem(at: 0)
        case .header: menu.selectItem(at: 1)
        case .body: menu.selectItem(at: 2)
        }
        
        menu.show(self)
    }
    
    
}

//MARK: - RichTextViewDelegate
extension EntryViewController: RichTextViewDelegate {
    func richTextView(didChangeStyle style: RichTextView.TextStyle) {
        toolbar.updateStyleButton(style)
        
    }
    
    func richTextViewDidBeginEditing() {
        
    }
    
    func richTextViewDidEndEditing() {
        
    }
    
    func richTextViewDidChangeText() {
        styleMenu?.hide(animated: true, ignoreSelectedItem: true)
        lastEdit = Date()
    }
    
    func richTextViewDidScroll() {
        let offset = textView.contentOffset.y + textView.contentInset.top
        topView.alpha = (offset - 20)/20
    }
    
    func richTextViewDidChangeSelection() {
        if textView.isFirstResponder {
            scrollTextView()
        }
    }
    
    func scrollTextView() {
        let selectionFrame = textView.currentSelectionRect
        
        let visibleFrame = CGRect(
            x: 0, y: textView.contentOffset.y,
            width: textView.bounds.width,
            height: textView.bounds.height - textView.contentInset.bottom).insetBy(dx: 0, dy: 32)
        
        if visibleFrame.contains(selectionFrame.center) {
            return
        }
        
        var newOffset: CGFloat
        if selectionFrame.center.y < visibleFrame.minY {
            newOffset = selectionFrame.minY - 32
        } else {
            newOffset = selectionFrame.maxY - visibleFrame.height
        }
        
        UIView.animateWithCurve(duration: 0.4, curve: UIView.CustomAnimationCurve.cubic.easeOut, animation: {
            self.textView.setContentOffset(
                CGPoint(x: 0, y: newOffset), animated: false)
        }, completion: nil)

        
    }
}

class RichTextToolbar: DoneToolbar {
        
    public let styleButton = StyleButton()
    
    override init() {
        super.init()
        
        self.bounds.size.height = 49
        
        contentView.color = Colors.barSeparator
        
        contentView.addSubview(styleButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        styleButton.sizeToFit()
        styleButton.frame.origin = CGPoint(x: 8, y: contentView.bounds.midY - styleButton.bounds.height/2)
        
    }
    
    public func updateStyleButton(_ style: RichTextView.TextStyle) {
        switch style {
        case .title: styleButton.label.text = "Title"
        case .header: styleButton.label.text = "Header"
        case .body: styleButton.label.text = "Body"
        }
        setNeedsLayout()
    }
    
    class StyleButton: PushButton {

        private let iconView = IconView()
        public let label = UILabel()
        
        override init() {
            super.init()
            
            iconView.backgroundColor = Colors.lightBackground
            iconView.icon = UIImage(named: "MenuTitle")
            iconView.iconColor = Colors.foregroundColor.withAlphaComponent(0.9)
            iconView.iconInsets = UIEdgeInsets(3)
            self.addSubview(iconView)
            
            label.text = "Title"
            label.font = Fonts.medium.withSize(16)
            label.textColor = Colors.text
            self.addSubview(label)
            
            self.backgroundColor = Colors.lightColor
            
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError()
        }
        
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let width = label.sizeThatFits(size).width + 24 + 6 + 10 + 14
            let height: CGFloat = 35
            return CGSize(width: width, height: height)
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.cornerRadius = self.bounds.height/2
            
            label.sizeToFit()
            
            iconView.frame = CGRect(x: 0, y: 0, width: self.bounds.height, height: self.bounds.height).insetBy(dx: 6, dy: 6)
            iconView.roundCorners()
            
            label.frame = CGRect(x: iconView.frame.maxX + 10, y: 0, width: label.bounds.width, height: self.bounds.height-1)
                    
        }
    }
}

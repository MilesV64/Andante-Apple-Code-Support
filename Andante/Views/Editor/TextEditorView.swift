//
//  TextEditorView.swift
//  Andante
//
//  Created by Miles Vinson on 4/4/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import MobileCoreServices

class TextEditorViewController: UIViewController {
    
    let textEditor = TextEditorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textEditor.presentingViewController = self
        textEditor.headerView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 100))
        view.addSubview(textEditor)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        textEditor.frame = self.view.bounds
    }
    
}

class TextEditorView: UIView {
    
    public weak var presentingViewController: UIViewController?
    
    private let scrollView = UIScrollView()
    
    public var headerView: UIView?
    private var blocks: [TextEditorBlockView] = []
    
    private let toolbar = TextEditorToolbar()
    private var toolbarPicker: ToolbarPickerView?
    private var keyboardFrame: CGRect = .zero
    
    private let tapGesture = UITapGestureRecognizer()
    
    private var imageViewer: TextEditorImageViewer?
    
    private var editingIndex: Int = 0
    
    init() {
        super.init(frame: .zero)
        
        scrollView.backgroundColor = Colors.foregroundColor
        addSubview(scrollView)
        
        toolbar.delegate = self
        toolbar.alpha = 0
        addSubview(toolbar)
        
        tapGesture.addTarget(self, action: #selector(handleTap))
        scrollView.addGestureRecognizer(tapGesture)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        let titleBlock = TextEditorTextBlockView(.body)
        addBlock(titleBlock)
        
        //titleBlock.becomeFirstResponder()
        
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = convert(keyboardScreenEndFrame, from: window)

        let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval

        let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            keyboardFrame = .zero
        } else {
            keyboardFrame = keyboardViewEndFrame
        }
        
        UIView.animate(
            withDuration: animationDuration ?? 0.25,
            delay: 0.0,
            options: UIView.AnimationOptions(rawValue: curve ?? 0),
            animations: {
                
                self.layoutToolbar()
                self.layoutToolbarPicker()
                self.layoutScrollView()
                
            },
            completion: nil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        if let block = editingBlock() {
            block.resignFirstResponder()
        }
        else {
            let location = gesture.location(in: scrollView)
            if let headerView = self.headerView {
                if headerView.frame.contains(location) {
                    return
                }
            }
            
            if let block = blocks.last, block.blockType == .text {
                block.becomeFirstResponder()
            } else {
                let block = TextEditorTextBlockView(.body)
                addBlock(block)
                block.becomeFirstResponder()
            }
            
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageViewer?.frame = self.bounds
        
        scrollView.frame = self.bounds
        
        layoutToolbar()
        layoutToolbarPicker()
        
        let (width, _, extraMargin) = constrainedWidth(600)
                
        if let headerView = headerView {
            headerView.frame = CGRect(
                x: extraMargin, y: 0,
                width: width,
                height: headerView.bounds.size.height)
        }
        
        layoutBlocks()
        
        layoutScrollView()

    }
    
    private func layoutBlocks() {
        let (width, _, extraMargin) = constrainedWidth(600)
        
        var minY: CGFloat = headerView?.frame.maxY ?? 0
        
        for block in blocks {
            let height = block.height(for: width)
            block.frame = CGRect(
                x: extraMargin, y: minY,
                width: width,
                height: height)
            minY += height
            //stop laying out if out of scrollview bounds
            
        }
        
        scrollView.contentSize.height = minY
    }
    
    private func layoutBlock(at index: Int) {
        let (width, _, extraMargin) = constrainedWidth(600)
        
        var minY: CGFloat = headerView?.frame.maxY ?? 0
        
        for (i, block) in blocks.enumerated() {
            if i < index {
                minY += block.height(for: width)
            }
            if i > index {
                break
            }
            else if i == index {
                let height = block.height(for: width)
                block.frame = CGRect(
                    x: extraMargin, y: minY,
                    width: width,
                    height: height)
                minY += height
            }
            
        }
        
        if index == blocks.count - 1 {
            scrollView.contentSize.height = minY
        }
        
    }
    
    private func layoutToolbar() {
        if keyboardFrame == .zero {
            toolbar.frame = CGRect(
                x: 0, y: bounds.maxY - safeAreaInsets.bottom - 48,
                width: bounds.width,
                height: 48 + safeAreaInsets.bottom)
        } else {
            toolbar.frame = CGRect(
                x: 0, y: bounds.maxY - keyboardFrame.height - 48,
                width: bounds.width,
                height: 48)
        }
    }
    
    private func layoutToolbarPicker() {
        toolbarPicker?.contextualFrame = CGRect(
            x: Constants.margin/2,
            y: toolbar.frame.minY - 10 - 88 + 48,
            width: bounds.width - Constants.margin,
            height: 88)
    }
    
    private func layoutScrollView() {
        scrollView.contentInset.bottom = keyboardFrame.height + toolbar.bounds.height + 54
        scrollView.verticalScrollIndicatorInsets.bottom = scrollView.contentInset.bottom - scrollView.safeAreaInsets.bottom - 54
    }
}

private extension TextEditorView {
    
    func addBlock(_ block: TextEditorBlockView) {
        block.delegate = self
        scrollView.addSubview(block)
        blocks.append(block)
    }
    
    func insertBlock(_ block: TextEditorBlockView, at index: Int) {
        block.delegate = self
        scrollView.addSubview(block)
        blocks.insert(block, at: index)
    }
    
    func deleteBlock(at index: Int) {
        if index > 0, let textBlock = blocks[index - 1] as? TextEditorTextBlockView {
            textBlock.setCursorAtEnd()
            textBlock.becomeFirstResponder()
        }
        
        blocks[index].resignFirstResponder()
        blocks[index].removeFromSuperview()
        blocks.remove(at: index)
    }
    
}

extension TextEditorView: TextEditorBlockDelegate {
    
    func editingBlock() -> TextEditorTextBlockView? {
        for block in self.blocks {
            if let block = block as? TextEditorTextBlockView, block.isEditing {
                return block
            }
        }
        return nil
    }
    
    func textEditorBlockDidChangeSize(_ block: TextEditorBlockView) {
        UIView.animateWithCurve(duration: 0.5, curve: UIView.CustomAnimationCurve.exponential.easeOut, animation: {
            self.layoutBlocks()
            block.layoutSubviews()
        }, completion: nil)
    }
    
    func textEditorBlockWillStartEditing(_ block: TextEditorTextBlockView) {
        if editingBlock() == nil {
            //start text editing
            
            self.toolbar.show(animated: false)
            UIView.animate(withDuration: 0.25) {
                self.toolbar.alpha = 1
            }
            
            block.showBackground(animated: true)
        }
        else {
            block.showBackground(animated: false)
        }
    }
    
    func textEditorBlockDidEndEditing(_ block: TextEditorTextBlockView) {
        if editingBlock() == nil {
            //end text editing
            UIView.animate(withDuration: 0.25) {
                self.toolbar.alpha = 0
                self.toolbarPicker?.alpha = 0
            } completion: { (complete) in
                self.toolbarPicker?.removeFromSuperview()
                self.toolbarPicker = nil
            }

            block.hideBackground(animated: true)
        }
        else {
            block.hideBackground(animated: false)
        }
    }
    
    
    func textEditorBlockDidReturn(_ block: TextEditorTextBlockView, trailingText: String) {
        if let index = blocks.firstIndex(of: block) {
            let newBlock: TextEditorTextBlockView
            
            if block.textStyle == .bullet {
                newBlock = TextEditorTextBlockView(.bullet)
            }
            else {
                newBlock = TextEditorTextBlockView(.body)
            }
            
            newBlock.string = trailingText
            newBlock.setCursorAtStart()
            
            insertBlock(newBlock, at: index + 1)
            layoutBlock(at: index + 1)
            
            UIView.animateWithCurve(duration: 0.4, curve: UIView.CustomAnimationCurve.exponential.easeOut, animation: {
                self.layoutBlocks()
            }, completion: nil)
            
            newBlock.becomeFirstResponder()
        }
        
    }
    
    func textEditorBlockDidDelete(_ block: TextEditorTextBlockView) {
        if let index = blocks.firstIndex(of: block) {
            
            if block.textStyle == .bullet {
                block.textStyle = .body
                return
            }
            
            deleteBlock(at: index)
            
            UIView.animateWithCurve(duration: 0.5, curve: UIView.CustomAnimationCurve.exponential.easeOut, animation: {
                self.layoutBlocks()
            }, completion: nil)
        }
    }
    
    func textEditorBlockDidChangeSelection(_ block: TextEditorTextBlockView, selectionFrame: CGRect) {
        scroll(to: block.convert(selectionFrame, to: scrollView))
    }
    
    func scroll(to rect: CGRect) {
        let visibleFrame = CGRect(
            x: 0, y: scrollView.contentOffset.y,
            width: scrollView.bounds.width,
            height: scrollView.bounds.height - (keyboardFrame.height + toolbar.bounds.height)
        ).insetBy(dx: 0, dy: 32)
        
        if visibleFrame.contains(rect.center) {
            return
        }
        
        var newOffset: CGFloat
        if rect.center.y < visibleFrame.minY {
            newOffset = rect.minY - 32
        } else {
            newOffset = rect.maxY - visibleFrame.height - 32
        }
        
        UIView.animateWithCurve(duration: 0.4, curve: UIView.CustomAnimationCurve.cubic.easeOut, animation: {
            self.scrollView.setContentOffset(
                CGPoint(x: 0, y: newOffset), animated: false)
        }, completion: nil)
    }
    
    func textEditorBlockDidSelectImage(_ block: TextEditorImageBlockView, imageView: UIImageView) {
        editingBlock()?.resignFirstResponder()
        
        let imageViewer = TextEditorImageViewer(imageView)
        imageViewer.frame = self.bounds
        self.imageViewer = imageViewer
        self.addSubview(imageViewer)

        imageViewer.animate {
            [weak self] in
            guard let self = self else { return }
            
        }
        
        imageViewer.closeHandler = {
            [weak self] in
            guard let self = self else { return }
            self.imageViewer?.removeFromSuperview()
            self.imageViewer = nil
        }
    }
    
    func textEditorBlockDidSelectVideo(_ block: TextEditorImageBlockView, url: URL) {
        editingBlock()?.resignFirstResponder()
        
        let playerController = AVPlayerViewController()
        playerController.player = AVPlayer(url: url)
        
        presentingViewController?.present(playerController, animated: true, completion: {
            playerController.player?.play()
        })
        
    }
    
}

extension TextEditorView: TextEditorToolbarDelegate {
    
    func presentToolbarPicker(config: ((ToolbarPickerView)->())?) {
        toolbar.hide()
        
        let picker = ToolbarPickerView()
        
        config?(picker)
        
        picker.willClose = {
            [weak self] in
            guard let self = self else { return }
            self.toolbar.show(delay: true)
        }
        
        picker.didClose = {
            [weak self] in
            guard let self = self else { return }
            picker.removeFromSuperview()
            self.toolbarPicker = nil
        }
        
        self.toolbarPicker = picker

        picker.alpha = 0
        picker.transform = CGAffineTransform(translationX: 0, y: picker.bounds.height + 16)
        
        self.insertSubview(picker, belowSubview: toolbar)
        layoutToolbarPicker()
        
        UIView.animate(withDuration: 0.35, delay: 0.05, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
            picker.alpha = 1
            picker.transform = .identity
        }, completion: nil)
    }
    
    func toolbarDidSelectTextStyle() {
        guard let block = editingBlock() else { return }
        let selectedStyle = block.textStyle
        
        presentToolbarPicker { picker in
            picker.addOption(title: "Title", icon: "text.title", isSelected: selectedStyle == .title) {
                block.textStyle = .title
            }
            
            picker.addOption(title: "Header", icon: "text.header", isSelected: selectedStyle == .header) {
                block.textStyle = .header
            }
            
            picker.addOption(title: "Body", icon: "textformat", isSelected: selectedStyle == .body) {
                block.textStyle = .body
            }
            
            picker.addOption(title: "Bullet", icon: "list.bullet", isSelected: selectedStyle == .bullet) {
                block.textStyle = .bullet
            }
            
            picker.addOption(title: "Numbers", icon: "list.number", isSelected: selectedStyle == .numbered) {
                block.textStyle = .numbered
            }
        }
    }
    
    func toolbarDidSelectPhotoLibrary() {
        guard
            let block = editingBlock(),
            let index = blocks.firstIndex(of: block)
        else { return }
        
        self.editingIndex = index
        self.editingBlock()?.resignFirstResponder()
        //TODO handle permissions
        let picker = UIImagePickerController()
        picker.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
        picker.delegate = self
        picker.sourceType = .photoLibrary
        self.presentingViewController?.present(picker, animated: true, completion: nil)
    }
    
    func toolbarDidSelectCamera() {
        guard
            let block = editingBlock(),
            let index = blocks.firstIndex(of: block)
        else { return }
        
        self.editingIndex = index
        self.editingBlock()?.resignFirstResponder()
        //TODO handle permissions
        let picker = UIImagePickerController()
        picker.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
        picker.delegate = self
        picker.sourceType = .camera
        
        self.presentingViewController?.present(picker, animated: true, completion: nil)
    }
    
    func toolbarDidSelectSketch() {
        
    }
    
    func toolbarDidSelectDone() {
        for block in blocks {
            if block.isFirstResponder {
                block.resignFirstResponder()
            }
        }
    }
    
}

extension TextEditorView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        picker.dismiss(animated: true, completion: nil)
        
        var block: TextEditorBlockView? = nil
        if let image = info[.originalImage] as? UIImage {
            let imageBlock = TextEditorImageBlockView()
            imageBlock.setImage(image)
            block = imageBlock
        }
        else if let url = info[.mediaURL] as? URL {
            let videoBlock = TextEditorImageBlockView()
            videoBlock.videoURL = url
            //display loading, include fallback placeholder image
            generateThumbnail(url) {
                [weak self] (image) in
                guard let self = self else { return }
                videoBlock.setImage(image, aspect: self.videoAspect(url))
                self.layoutBlocks()
            }
            block = videoBlock
        }
        
        if let block = block {
            if let textBlock = blocks[editingIndex] as? TextEditorTextBlockView, textBlock.string.isEmpty {
                deleteBlock(at: editingIndex)
                insertBlock(block, at: editingIndex)
            }
            else {
                insertBlock(block, at: editingIndex+1)
            }
            
            layoutBlocks()
        }
        
        
    }
    
    private func videoAspect(_ url: URL) -> CGFloat? {
        guard let track = AVAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return nil }
        let size = track.naturalSize.applying(track.preferredTransform)
        guard size.height != 0 && size.width != 0 else { return nil }
        return abs(size.height) / abs(size.width)
    }
    
    private func generateThumbnail(_ url: URL, completion: ((UIImage?)->())?) {
        let imageGenerator = AVAssetImageGenerator(asset: AVAsset(url: url))
        imageGenerator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.0, preferredTimescale: 600)
        let times = [NSValue(time: time)]
        imageGenerator.generateCGImagesAsynchronously(forTimes: times, completionHandler: {
            _, image, _, _, _ in
            
            DispatchQueue.main.async {
                if let image = image {
                    completion?(UIImage(cgImage: image))
                } else {
                    completion?(nil)
                }
            }
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

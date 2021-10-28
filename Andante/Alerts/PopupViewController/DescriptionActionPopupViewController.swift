////
////  DescriptionActionPopupViewController.swift
////  Andante
////
////  Created by Miles Vinson on 2/28/21.
////  Copyright © 2021 Miles Vinson. All rights reserved.
////
//
//import UIKit
//
//class DescriptionActionPopupViewController: PopupViewController {
//
//    private let titleLabel = UILabel()
//    private let textView = UITextView()
//    private let actionButton = PushButton()
//
//    public var titleText: String? {
//        didSet {
//            titleLabel.text = titleText
//        }
//    }
//
//    public var descriptionText: String? {
//        didSet {
//            textView.text = descriptionText
//        }
//    }
//
//    public var actionText: String? {
//        didSet {
//            actionButton.setTitle(actionText ?? "Confirm", color: Colors.white, font: Fonts.semibold.withSize(16))
//        }
//    }
//
//    public var action: (()->Void)? {
//        didSet {
//            actionButton.action = {
//                [weak self] in
//                guard let self = self else { return }
//                self.closeCompletion = {
//                    [weak self] in
//                    guard let self = self else { return }
//                    self.action?()
//                }
//                self.close()
//            }
//        }
//    }
//
//    public var cancelAction: (()->Void)?
//    private var shouldEvokeCancelAction = true
//
//    convenience init(title: String?, description: String?, actionText: String?, action: (()->Void)?) {
//        self.init()
//
//        titleLabel.text = title
//        textView.text = description
//        actionButton.setTitle(actionText ?? "Confirm", color: Colors.white, font: Fonts.semibold.withSize(16))
//        actionButton.action = {
//            [weak self] in
//            guard let self = self else { return }
//            self.shouldEvokeCancelAction = false
//            self.closeCompletion = {
//                action?()
//            }
//            self.close()
//        }
//
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        titleLabel.textColor = Colors.text
//        titleLabel.font = Fonts.semibold.withSize(17)
//        titleLabel.textAlignment = .center
//        self.contentView.addSubview(titleLabel)
//
//        textView.font = Fonts.regular.withSize(16)
//        textView.textColor = Colors.lightText
//        textView.textContainerInset.left = Constants.margin + 5
//        textView.textContainerInset.right = Constants.margin + 5
//        textView.textAlignment = .center
//        textView.isScrollEnabled = false
//        textView.isEditable = false
//        textView.backgroundColor = .clear
//        self.contentView.addSubview(textView)
//
//        actionButton.backgroundColor = Colors.orange
//        self.contentView.addSubview(actionButton)
//
//    }
//
//    override func viewDidLayoutSubviews() {
//
//        let titleHeight = titleLabel.sizeThatFits(
//            CGSize(width: contentView.bounds.width, height: .infinity)).height
//
//        let textHeight = textView.sizeThatFits(
//            CGSize(width: contentView.bounds.width, height: .infinity)).height
//
//        let buttonHeight: CGFloat = 50
//
//        self.preferredContentHeight = titleHeight + textHeight + buttonHeight + 22 + 44
//
//        super.viewDidLayoutSubviews()
//
//        titleLabel.frame = CGRect(
//            x: 0, y: 24,
//            width: contentView.bounds.width, height: titleHeight)
//
//        textView.frame = CGRect(
//            x: 0, y: titleLabel.frame.maxY,
//            width: contentView.bounds.width, height: textHeight)
//
//        actionButton.frame = CGRect(
//            x: Constants.margin, y: self.contentView.bounds.maxY - buttonHeight - 22 - contentView.safeAreaInsets.bottom,
//            width: contentView.bounds.width - Constants.margin*2,
//            height: buttonHeight)
//
//        actionButton.cornerRadius = 12
//
//
//    }
//
//    override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//
//        if shouldEvokeCancelAction {
//            print("Canceling")
//            self.cancelAction?()
//        }
//    }
//
//
//}
//
//
//

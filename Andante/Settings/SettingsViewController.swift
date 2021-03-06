//
//  SettingsViewController.swift
//  Andante
//
//  Created by Miles Vinson on 7/8/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit
import MessageUI
import Combine

class SettingsViewController: UIViewController {
    
    private let headerView = SettingsHeaderView()
        
    private let profileCell = SettingsProfileView()
    private let separator = Separator()
    
    private let versionLabel = UILabel()
    
    private let siriShortcutsCell = SettingsOptionView(
        title: "Siri Shortcuts",
        iconName: "mic.fill",
        iconColor: UIColor("#2096F3"))
    
    private let premiumCell = SettingsUpgradeView()
    
    private let exportCell = SettingsOptionView(
        title: "Export Practice Log",
        iconName: "arrow.up.doc.fill",
        iconColor: Colors.green)
    
    private let remindersCell = SettingsOptionView(
        title: "Practice Reminders",
        iconName: "alarm.fill",
        iconColor: UIColor.systemPurple)
    
    private let separator2 = Separator()
    private let separator3 = Separator()
    private let separator4 = Separator()
    
    private let shareCell = SettingsOptionView(
        title: "Share Andante",
        iconName: "square.and.arrow.up.fill",
        iconColor: UIColor("#5D7DEA"))
    
    private let reviewCell = SettingsOptionView(
        title: "Review Andante",
        iconName: "heart.fill",
        iconColor: UIColor("#FD606D"))
    
    private let feedbackCell = SettingsOptionView(
        title: "Send Me Feedback",
        iconName: "ellipsis.bubble.fill",
        iconColor: Colors.focusColor)
    
    private let helpCell = SettingsOptionView(
        title: "Help",
        iconName: "questionmark.circle.fill",
        iconColor: Colors.lightBlue)
    
    private let cloudCell = SettingsOptionView(
        title: "iCloud Sync Support",
        iconName: "cloud.fill",
        iconColor: Colors.purple)
    
    private let contactCell = SettingsOptionView(
        title: "Contact Me",
        iconName: "envelope.fill",
        iconColor: Colors.sessionsColor)
    
    private let instagramCell = SettingsOptionView(
        title: "Andante on Instagram",
        iconName: "instagram",
        iconColor: UIColor("FD6099"))
    
    private let twitterCell = SettingsOptionView(
        title: "Andante on Twitter",
        iconName: "twitter",
        iconColor: UIColor("1DA1F2"))
    
    private var cells: [SettingsCellView]!
    
    private let handleView = HandleView()
    private let scrollView = CancelTouchScrollView()
    
    private var appTweaksGestureRecognizer: UITapGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.tintAdjustmentMode = .automatic
        
        cells = [
            self.siriShortcutsCell,
            self.remindersCell,
            self.exportCell,
            self.helpCell,
            self.cloudCell,
            self.reviewCell,
            self.feedbackCell,
            self.contactCell,
            self.instagramCell,
        ]

        if Settings.isPremium == false  {
            cells.insert(premiumCell, at: 0)
        }
        
        self.view.backgroundColor = Colors.foregroundColor
        
        scrollView.backgroundColor = Colors.foregroundColor
        self.view.addSubview(scrollView)
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        headerView.changeProfileButton.action = {
            [weak self] in
            guard let self = self else { return }
            
            if CDProfile.getAllProfiles().count > 1 {
                let changeProfilePopup = ProfilesPopupViewController()
                changeProfilePopup.title = "Change Profile"
                changeProfilePopup.selectedProfile = User.getActiveProfile()
                
                changeProfilePopup.action = {
                    [weak self] profile in
                    guard let self = self else { return }
                    self.changeProfile(to: profile)
                }
                
                changeProfilePopup.newProfileAction = {
                    [weak self] in
                    guard let self = self else { return }
                    self.newProfile()
                }
                
                self.presentPopupViewController(changeProfilePopup)
            }
            else {
                let descriptionActionAlert = DescriptionActionPopupViewController(
                    title: "You only have one profile!",
                    description: "Use multiple profiles to conveniently track your progress with every art, skill, and craft you're practicing.",
                    actionText: "New Profile") {
                        [weak self] in
                        guard let self = self else { return }
                        self.newProfile()
                }
                
                self.presentPopupViewController(descriptionActionAlert)
                
            }
            
            
        }
        scrollView.addSubview(headerView)
        
        profileCell.profile = User.getActiveProfile()
        profileCell.action = {
            [weak self] in
            guard let self = self, let profile = User.getActiveProfile() else { return }
            self.addChildTransitionController(ProfileSettingsViewController(profile: profile))
        }
        scrollView.addSubview(profileCell)
        
        separator.position = .middle
        scrollView.addSubview(separator)
        
        separator2.position = .middle
        scrollView.addSubview(separator2)
        
        separator3.position = .middle
        scrollView.addSubview(separator3)
        
        separator4.position = .middle
        scrollView.addSubview(separator4)
        
        cells.forEach { (option) in
            option.delegate = self
            scrollView.addSubview(option)
        }
                
        versionLabel.text = storeVersionNumber
        versionLabel.textColor = Colors.lightText
        versionLabel.font = Fonts.regular.withSize(13)
        versionLabel.textAlignment = .center
        scrollView.addSubview(versionLabel)
        
        scrollView.addSubview(handleView)
        
        #if DEBUG
        self.appTweaksGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.showAppTweaks))
        self.versionLabel.addGestureRecognizer(self.appTweaksGestureRecognizer!)
        self.versionLabel.isUserInteractionEnabled = true
        #endif
                
    }
    
    @objc func didTapDone() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func showAppTweaks() {
        let appTweaksViewController = AppTweaksViewController()
        appTweaksViewController.delegate = self
        self.present(UINavigationController(rootViewController: appTweaksViewController), animated: true, completion: nil)
    }
    
    private func showPremiumController() {
        let vc = AndanteProViewController()
        vc.successAction = { [weak self] in
            self?.reloadPremiumCell()
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    private func reloadPremiumCell() {
        if Settings.isPremium && self.cells.first! === self.premiumCell {
            self.cells.removeFirst().removeFromSuperview()
        }
        else if Settings.isPremium == false && self.cells.first! !== self.premiumCell {
            self.premiumCell.delegate = self
            self.scrollView.addSubview(self.premiumCell)
            self.cells.insert(self.premiumCell, at: 0)
        }
        self.view.setNeedsLayout()
    }
    
    private func newProfile() {
        if Settings.isPremium {
            let newProfileVC = CreateProfileViewController()
            newProfileVC.handler = {
                [weak self] profile in
                guard let self = self else { return }
                self.changeProfile(to: profile)
            }
            self.present(newProfileVC, animated: true, completion: nil)
        }
        else {
            showPremiumController()
        }
        
    }
    
    public func changeProfile(to profile: CDProfile) {
        User.setActiveProfile(profile)
        
        if let container = self.presentingViewController as? AndanteViewController {
            container.didChangeProfile(profile)
        }
        
        UIView.transition(with: profileCell, duration: 0.1, options: [.transitionCrossDissolve], animations: {
            self.profileCell.profile = profile
        }, completion: nil)
        
        UIView.transition(with: headerView, duration: 0.1, options: [.transitionCrossDissolve], animations: {
            self.headerView.profile = profile
        }, completion: nil)
    
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let separatorInset = UIEdgeInsets(
            top: 0, left: view.responsiveMargin,
            bottom: 0, right: view.responsiveMargin)
        separator.inset = separatorInset
        separator2.inset = separatorInset
        separator3.inset = separatorInset
        separator4.inset = separatorInset
        
        scrollView.frame = self.view.bounds
        
        handleView.frame = CGRect(x: 0, y: 0, width: scrollView.bounds.width, height: 20)
        
        headerView.frame = CGRect(
            x: 0, y: 0,
            width: scrollView.bounds.width, height: 282)
        
        let cellHeight: CGFloat = 76
        
        profileCell.frame = CGRect(
            x: 0, y: headerView.frame.maxY,
            width: self.view.bounds.width,
            height: cellHeight)
        
        separator.frame = CGRect(
            x: 0, y: profileCell.frame.maxY,
            width: scrollView.bounds.width,
            height: 20)
        
        var minY: CGFloat = separator.frame.maxY
        
        let group1 = cells.contains(premiumCell) ? 4 : 3
        for i in 0..<group1 {
            cells[i].frame = CGRect(
                x: 0, y: minY,
                width: self.view.bounds.width,
                height: cellHeight)
            minY += cellHeight
        }
        
        separator2.frame = CGRect(
            x: 0, y: minY,
            width: scrollView.bounds.width,
            height: 20)
        minY = separator2.frame.maxY
        
        let group2 = 2
        for i in group1..<(group1+group2) {
            cells[i].frame = CGRect(
                x: 0, y: minY,
                width: self.view.bounds.width,
                height: cellHeight)
            minY += cellHeight
        }
        
        separator3.frame = CGRect(
            x: 0, y: minY,
            width: scrollView.bounds.width,
            height: 20)
        minY = separator3.frame.maxY
        
        for i in (group1+group2)..<cells.count {
            cells[i].frame = CGRect(
                x: 0, y: minY,
                width: self.view.bounds.width,
                height: cellHeight)
            minY += cellHeight
        }
        
        separator4.frame = CGRect(
            x: 0, y: minY,
            width: scrollView.bounds.width,
            height: 20
        )
        
        
        versionLabel.frame = CGRect(
            x: self.view.bounds.midX - 50,
            y: separator4.frame.maxY + 4,
            width: 100,
            height: 32
        )
        
        scrollView.contentSize.height = versionLabel.frame.maxY + max(self.view.safeAreaInsets.bottom + 4, 24)
        
    }
    
}

extension SettingsViewController: SettingsOptionDelegate, MFMailComposeViewControllerDelegate {
    
    func didSelectOption(_ option: CustomButton) {
        
        if option === siriShortcutsCell {
            self.addChildTransitionController(SiriShortcutsViewController())
        }
        else if option === contactCell {
            handleMail()
        }
        else if option === reviewCell {
            handleReview()
        }
        else if option === remindersCell {
            handleReminders()
        }
        else if option === premiumCell {
            showPremiumController()
        }
        else if option === exportCell {
            handleExport()
        }
        else if option === helpCell {
            handleHelp()
        }
        else if option === cloudCell {
            handleCloud()
        }
        else if option === feedbackCell {
            if let url = URL(string: "https://airtable.com/shr8LpJHSEJUWIPJ2") {
                UIApplication.shared.open(url)
            }
        }
        else if option == twitterCell {
            if let url = URL(string: "https://twitter.com/AppAndante") {
                UIApplication.shared.open(url)
            }
        }
        else if option == instagramCell {
            if let url = URL(string: "https://www.instagram.com/andante_practice_journal/") {
                UIApplication.shared.open(url)
            }
        }
        
    }
    
    func handleExport() {
        if Settings.isPremium {
            let vc = ExportDataViewController()
            self.present(vc, animated: true, completion: nil)
        }
        else {
            showPremiumController()
        }
    }
    
    func handleReminders() {
        if Settings.isPremium {
            self.addChildTransitionController(RemindersViewController())
        }
        else {
            showPremiumController()
        }
    }
    
    func handleHelp() {
        if let url = URL(string: "https://andante.app/faq") {
            UIApplication.shared.open(url)
        }
    }
    
    func handleCloud() {
        let vc = CloudSupportViewController()
        vc.settingsViewController = self
        self.present(vc, animated: true, completion: nil)
    }
    
    func handleReview() {
        if let reviewURL = URL(string: "https://apps.apple.com/us/app/andante-practice-journal/id1530262372?action=write-review"), UIApplication.shared.canOpenURL(reviewURL) {
            UIApplication.shared.open(reviewURL, options: [:], completionHandler: nil)
        }
    }
    
    func handleShare() {
        if let urlStr = NSURL(string: "https://itunes.apple.com/us/app/myapp/idxxxxxxxx?ls=1&mt=8") {
            let objectsToShare = [urlStr]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)

            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    func handleMail() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.setToRecipients(["contact@andante.app"])
            mail.setSubject("Andante")
            mail.mailComposeDelegate = self
            self.present(mail, animated: true, completion: nil)

        } else {
            let alert = DescriptionActionPopupViewController(title: "Can't send mail", description: "Your device isn't configured to automatically send emails. Try copying the address instead!", actionText: "Copy Email", action: nil)
            alert.action = {
                UIPasteboard.general.string = "contact@andante.app"
            }
            self.presentPopupViewController(alert)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
}

extension SettingsViewController: AppTweaksViewControllerDelegate {
    
    func appTweaksViewController(didChangeAndantePro isPremium: Bool) {
        self.reloadPremiumCell()
    }
    
}


//MARK: - OptionView
protocol SettingsOptionDelegate: class {
    func didSelectOption(_ option: CustomButton)
}

class SettingsCellView: CustomButton {
    public weak var delegate: SettingsOptionDelegate?
}

class SettingsOptionView: SettingsCellView {
    
    private let iconViewBG = UIView()
    private let iconView = UIImageView()
    private let label = UILabel()
    private let arrow = IconView()
    
    private var offset: CGFloat = 0
    
    private var useFixedIconSize = false
    
    init(title: String?, iconName: String, iconColor: UIColor?) {
        super.init()
        
        iconViewBG.backgroundColor = iconColor
        
        if let image = UIImage(name: iconName, pointSize: 18, weight: .medium) {
            iconView.image = image
        } else {
            iconView.image = UIImage(named: iconName)
            useFixedIconSize = true
        }
       
        if iconName == "square.and.arrow.up.fill" {
            offset = 1
        }
        
        iconView.setImageColor(color: Colors.white)
        iconViewBG.roundCorners(Constants.iconBGCornerRadius)
        self.addSubview(iconViewBG)
        iconViewBG.addSubview(iconView)
        
        label.text = title
        
        if title == "Get Andante Pro" {
            label.textColor = Colors.orange
            label.font = Fonts.semibold.withSize(16)
        }
        else {
            label.textColor = Colors.text
            label.font = Fonts.medium.withSize(16)
        }
        self.addSubview(label)
        
        arrow.icon = UIImage(
            systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold))
        arrow.iconColor = Colors.extraLightText
        arrow.isUserInteractionEnabled = false
        self.addSubview(arrow)
        
        self.action = {
            self.delegate?.didSelectOption(self)
        }
        
        self.highlightAction = { isHighlighted in
            if isHighlighted {
                self.backgroundColor = Colors.cellHighlightColor
            }
            else {
                UIView.animate(withDuration: 0.2) {
                    self.backgroundColor = .clear
                }
            }
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let iconSize: CGFloat = Constants.iconBGSize.width
        iconViewBG.frame = CGRect(
            x: responsiveMargin,
            y: self.bounds.midY - iconSize/2,
            width: iconSize, height: iconSize)
        
        if useFixedIconSize {
            iconView.bounds.size = CGSize(24)
        }
        else {
            iconView.sizeToFit()
        }
        
        iconView.center = iconViewBG.bounds.center.offset(by: CGPoint(x: 0, y: -offset))
        
        label.sizeToFit()
        label.frame.origin = CGPoint(
            x: iconViewBG.frame.maxX + 14,
            y: iconViewBG.frame.midY - label.bounds.height/2)
        
        arrow.sizeToFit()
        arrow.frame.origin = CGPoint(
            x: self.bounds.maxX - arrow.bounds.width - responsiveSmallMargin,
            y: iconViewBG.frame.midY - arrow.bounds.height/2)
        
    }
}

class SettingsUpgradeView: SettingsCellView {
        
    private let iconViewBG = CAGradientLayer()
    private let iconView = UIImageView()
    private let label = LabelGroup()
    private let arrow = IconView()
    
    private var offset: CGFloat = 0
    
    override init() {
        super.init()
        
        iconViewBG.colors = [Colors.orange.withAlphaComponent(0.9).cgColor, Colors.orange.toColor(.systemRed, percentage: 20).cgColor]
        iconViewBG.startPoint = .zero
        iconViewBG.endPoint = CGPoint(x: 1, y: 1)
        iconViewBG.cornerRadius = Constants.iconBGCornerRadius
        iconViewBG.cornerCurve = .continuous
        
        iconView.image = UIImage(named: "AndanteProIcon")
        
        iconView.setImageColor(color: Colors.white)
        self.layer.addSublayer(iconViewBG)
        self.addSubview(iconView)
        
        label.titleLabel.text = "Get Andante Pro"
        label.titleLabel.textColor = Colors.orange
        label.titleLabel.font = Fonts.semibold.withSize(16)
        
        label.detailLabel.textColor = Colors.lightText
        label.detailLabel.font = Fonts.medium.withSize(14)
        label.padding = 0
        label.isUserInteractionEnabled = false
        self.addSubview(label)
        
        let taglines = [
            "Support indie development!",
            "Buy the dev a coffee!",
            "Cool features inside!",
            "👀",
            "Unlimited profiles!"
        ]
        label.detailLabel.text = taglines[Int.random(in: 0..<taglines.count)]
        
        arrow.icon = UIImage(
            systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold))
        arrow.iconColor = Colors.extraLightText
        arrow.isUserInteractionEnabled = false
        self.addSubview(arrow)
        
        self.action = {
            self.delegate?.didSelectOption(self)
        }
        
        self.highlightAction = { isHighlighted in
            if isHighlighted {
                self.backgroundColor = Colors.cellHighlightColor
            }
            else {
                UIView.animate(withDuration: 0.2) {
                    self.backgroundColor = .clear
                }
            }
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        iconViewBG.colors = [Colors.orange.withAlphaComponent(0.9).cgColor, Colors.orange.toColor(.systemRed, percentage: 20).cgColor]
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let iconSize: CGFloat = 38
        iconViewBG.frame = CGRect(
            x: responsiveMargin,
            y: self.bounds.midY - iconSize/2,
            width: iconSize, height: iconSize)
        
        iconView.frame = iconViewBG.frame.insetBy(dx: 2, dy: 2)
        
        label.sizeToFit()
        label.frame.origin = CGPoint(
            x: iconViewBG.frame.maxX + 14,
            y: iconViewBG.frame.midY - label.bounds.height/2)
        
        arrow.sizeToFit()
        arrow.frame.origin = CGPoint(
            x: self.bounds.maxX - arrow.bounds.width - responsiveMargin,
            y: iconViewBG.frame.midY - arrow.bounds.height/2)
        
    }
}

class SettingsProfileView: CustomButton {
        
    private let iconView = ProfileImageView()
    private let label = UILabel()
    private let arrow = IconView()
        
    public var profile: CDProfile? {
        didSet {
            if let profile = profile {
                iconView.profile = profile
            }
        }
    }
    
    override init() {
        super.init()
        
        iconView.cornerRadius = 10
        iconView.inset = 6
        self.addSubview(iconView)
        
        label.text = "Profile Settings"
        label.font = Fonts.medium.withSize(16)
        label.textColor = Colors.text
        self.addSubview(label)
        
        arrow.icon = UIImage(
            systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold))
        arrow.iconColor = Colors.extraLightText
        arrow.isUserInteractionEnabled = false
        self.addSubview(arrow)
        
        self.highlightAction = { isHighlighted in
            if isHighlighted {
                self.backgroundColor = Colors.cellHighlightColor
            }
            else {
                UIView.animate(withDuration: 0.2) {
                    self.backgroundColor = .clear
                }
            }
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let iconSize: CGFloat = 38
        iconView.frame = CGRect(
            x: responsiveMargin,
            y: self.bounds.midY - iconSize/2,
            width: iconSize, height: iconSize)
        
        label.sizeToFit()
        label.frame.origin = CGPoint(
            x: iconView.frame.maxX + 14,
            y: iconView.frame.midY - label.bounds.height/2)
        
        arrow.sizeToFit()
        arrow.frame.origin = CGPoint(
            x: self.bounds.maxX - arrow.bounds.width - responsiveSmallMargin,
            y: iconView.frame.midY - arrow.bounds.height/2)
        
    }
}


//MARK: - Header
class SettingsHeaderView: UIView {
    
    private let activeProfileIcon = ProfileImageView()
    private let activeProfileLabel = LabelGroup()
    public let changeProfileButton = PushButton()
    
    private var cancellables = Set<AnyCancellable>()
    
    public var profile: CDProfile? {
        didSet {
            
            cancellables.removeAll()
            profile?.publisher(for: \.name).sink {
                [weak self] name in
                guard let self = self else { return }
                self.activeProfileLabel.titleLabel.text = name
                self.setNeedsLayout()
            }.store(in: &cancellables)
            
            activeProfileIcon.profile = profile
            
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        let profile = User.getActiveProfile()
        
        activeProfileIcon.profile = profile
        activeProfileIcon.inset = 14
        self.addSubview(activeProfileIcon)
        
        activeProfileLabel.titleLabel.text = profile?.name
        activeProfileLabel.titleLabel.textColor = Colors.text
        activeProfileLabel.titleLabel.font = Fonts.bold.withSize(21)
        activeProfileLabel.detailLabel.text = "Current Profile"
        activeProfileLabel.detailLabel.textColor = Colors.lightText
        activeProfileLabel.detailLabel.font = Fonts.medium.withSize(15)
        activeProfileLabel.padding = 6
        activeProfileLabel.textAlignment = .center
        self.addSubview(activeProfileLabel)
        
        changeProfileButton.backgroundColor = Colors.orange
        changeProfileButton.setTitle("Change Profile", color: Colors.white, font: Fonts.semibold.withSize(16))
        changeProfileButton.setButtonShadow()
        self.addSubview(changeProfileButton)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        activeProfileIcon.frame = CGRect(x: self.bounds.midX - 94/2, y: 40,
                                             width: 94, height: 94)
        
        let height = activeProfileLabel.sizeThatFits(self.bounds.size).height
        activeProfileLabel.frame = CGRect(x: 40, y: activeProfileIcon.frame.maxY + 12,
                                          width: self.bounds.width - 80,
                                          height: height)
        
        let buttonWidth = self.bounds.width - responsiveMargin*2
        changeProfileButton.frame = CGRect(x: self.bounds.midX - buttonWidth/2, y: activeProfileLabel.frame.maxY + 24, width: buttonWidth, height: 50)
        changeProfileButton.cornerRadius = 12
            
        
    }
}

fileprivate class SocialMediaView: UIView {
    
    let twitter = SocialMediaButton("twitter", color: UIColor("1DA1F2"))
    let insta = SocialMediaButton("instagram", color: UIColor("FD6099"))
        
    init() {
        super.init(frame: .zero)
        
        self.addSubview(twitter)
        self.addSubview(insta)
        
        twitter.action = {
            if let url = URL(string: "https://twitter.com/AppAndante") {
                UIApplication.shared.open(url)
            }
        }
        
        insta.action = {
            if let url = URL(string: "https://www.instagram.com/andante_practice_journal/") {
                UIApplication.shared.open(url)
            }
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let itemSize: CGFloat = 52
        let spacing: CGFloat = 58
        
        let minX = self.bounds.midX - spacing/2 - itemSize
        let minY = self.bounds.midY - itemSize/2
        
        insta.frame = CGRect(
            x: minX, y: minY,
            width: itemSize, height: itemSize)
        
        twitter.frame = CGRect(
            x: insta.frame.maxX + spacing, y: minY,
            width: itemSize, height: itemSize)
        
    }
    
    class SocialMediaButton: CustomButton {
        
        init(_ iconName: String, color: UIColor?) {
            super.init()
            
            self.setImage(UIImage(named: iconName), for: .normal)
            self.tintColor = color
            
            self.imageEdgeInsets = UIEdgeInsets(14)
            self.adjustsImageWhenHighlighted = false
            
            self.highlightAction = {
                [weak self] highlighted in
                guard let self = self else { return }
                
                if highlighted {
                    UIView.animate(withDuration: 0.15) {
                        self.backgroundColor = self.tintColor.withAlphaComponent(0.15)
                    }
                } else {
                    UIView.animate(withDuration: 0.35) {
                        self.backgroundColor = .clear
                    }
                }
            }
            
            self.layer.borderWidth = 1.4
            self.layer.borderColor = Colors.separatorColor.cgColor
            
        }
        
        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            self.layer.borderColor = Colors.separatorColor.cgColor
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError()
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            self.layer.cornerRadius = self.bounds.width/2
        }
    }
}

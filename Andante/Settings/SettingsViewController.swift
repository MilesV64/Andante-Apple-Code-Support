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

class SettingsViewController: UIViewController, UIScrollViewDelegate, ProfileObserver {
    
    private let headerView = SettingsHeaderView()
        
    private let separator = Separator()
    
    private let versionLabel = UILabel()
    
    private let siriShortcutsCell = AndanteCellView(
        title: "Siri Shortcuts",
        icon: "mic.fill",
        iconColor: UIColor("#2096F3"))
    
    private let premiumCell = AndanteCellView(
        title: "Get Andante Pro",
        icon: "star.fill",
        iconColor: Colors.orange)
    
    private let exportCell = AndanteCellView(
        title: "Export Practice Log",
        icon: "arrow.up.doc.fill",
        iconColor: Colors.green)
    
    private let remindersCell = AndanteCellView(
        title: "Practice Reminders",
        icon: "alarm.fill",
        iconColor: UIColor.systemPurple)
    
    private let profilesLabel = UILabel()
    private let toolsLabel = UILabel()
    private let helpLabel = UILabel()
    private let andanteLabel = UILabel()
    
    private let shareCell = AndanteCellView(
        title: "Share Andante",
        icon: "square.and.arrow.up.fill",
        iconColor: UIColor("#5D7DEA"))
    
    private let reviewCell = AndanteCellView(
        title: "Review Andante",
        icon: "heart.fill",
        iconColor: UIColor("#FD606D"))
    
    private let feedbackCell = AndanteCellView(
        title: "Send Me Feedback",
        icon: "ellipsis.bubble.fill",
        iconColor: Colors.focusColor)
    
    private let helpCell = AndanteCellView(
        title: "Help",
        icon: "questionmark.circle.fill",
        iconColor: Colors.lightBlue)
    
    private let cloudCell = AndanteCellView(
        title: "iCloud Sync Support",
        icon: "cloud.fill",
        iconColor: Colors.purple)
    
    private let contactCell = AndanteCellView(
        title: "Contact Me",
        icon: "envelope.fill",
        iconColor: Colors.sessionsColor)
    
    private let instagramCell = AndanteCellView(
        title: "Andante on Instagram",
        icon: UIImage(named: "instagram"),
        imageSize: CGSize(width: 22, height: 22),
        iconColor: UIColor("FD6099"))
    
    private var cells: [AndanteCellView]!
    
    private let scrollView = CancelTouchScrollView()
    
    private let changeProfileButton = PushButton()
    
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
        
        premiumCell.label.font = Fonts.semibold.withSize(17)
        premiumCell.label.textColor = Colors.orange
        premiumCell.accessoryStyle = .arrow
        premiumCell.margin = 24

        if Settings.isPremium == false  {
            cells.insert(premiumCell, at: 0)
        }
        
        self.view.backgroundColor = Colors.foregroundColor
        
        scrollView.backgroundColor = Colors.foregroundColor
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        self.view.addSubview(scrollView)
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        changeProfileButton.backgroundColor = Colors.orange
        changeProfileButton.setButtonShadow(floating: false)
        changeProfileButton.setTitle("Change Profile", color: Colors.white, font: Fonts.semibold.withSize(16))
        self.scrollView.addSubview(changeProfileButton)
        
        changeProfileButton.action = {
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
                let alert = ActionTrayPopupViewController(
                    title: "You only have one profile!",
                    description: "Use multiple profiles to conveniently track your progress with every art, skill, and craft you're practicing."
                )
                
                alert.addAction("New Profile") { [weak self] in
                    self?.newProfile()
                }
                
                self.presentPopupViewController(alert)
                
            }
            
            
        }
        
        self.view.addSubview(headerView)
        
        profilesLabel.text = "PROFILES"
        toolsLabel.text = "TOOLS"
        helpLabel.text = "SUPPORT"
        andanteLabel.text = "ANDANTE"
        
        [profilesLabel, toolsLabel, helpLabel, andanteLabel].forEach { label in
            label.textColor = Colors.lightText
            label.font = Fonts.semibold.withSize(13)
            scrollView.addSubview(label)
        }
        
        cells.forEach { (option) in
            option.action = { [weak self] in self?.didSelectOption(option) }
            option.margin = 24
            option.accessoryStyle = .arrow
            scrollView.addSubview(option)
        }
                
        versionLabel.text = storeVersionNumber
        versionLabel.textColor = Colors.lightText
        versionLabel.font = Fonts.regular.withSize(13)
        versionLabel.textAlignment = .center
        scrollView.addSubview(versionLabel)
        
        self.reloadProfiles()
        
        ProfileManager.shared.addObserver(self)
            
        #if DEBUG
        self.appTweaksGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.showAppTweaks))
        self.versionLabel.addGestureRecognizer(self.appTweaksGestureRecognizer!)
        self.versionLabel.isUserInteractionEnabled = true
        #endif
                
    }
    
    private var profileCells: [AndanteCellView] = []
    
    func profileManager(_ profileManager: ProfileManager, didAddProfile profile: CDProfile) {
        self.reloadProfiles()
    }
    
    func profileManager(_ profileManager: ProfileManager, didDeleteProfile profile: CDProfile) {
        self.reloadProfiles()
    }
    
    private func reloadProfiles() {
        profileCells.forEach { $0.removeFromSuperview() }
        profileCells.removeAll()
        
        for profile in CDProfile.getAllProfiles() {
            let profileCell = AndanteCellView(profile: profile)
            profileCell.action = { [weak self] in
                self?.addChildTransitionController(ProfileSettingsViewController(profile: profile))
            }
            profileCell.margin = 24
            profileCell.accessoryStyle = .arrow
            profileCells.append(profileCell)
            scrollView.addSubview(profileCell)
        }
        
        self.view.setNeedsLayout()
    }
    
    @objc func showAppTweaks() {
        let appTweaksViewController = AppTweaksViewController()
        appTweaksViewController.delegate = self
        
        let navController = UINavigationController(rootViewController: appTweaksViewController)
        if #available(iOS 15.0, *) {
            navController.sheetPresentationController?.detents = [.medium(), .large()]
            navController.sheetPresentationController?.selectedDetentIdentifier = .medium
        }
        self.presentModal(navController, animated: true, completion: nil)
    }
    
    private func showPremiumController() {
        let vc = AndanteProViewController()
        vc.successAction = { [weak self] in
            self?.reloadPremiumCell()
        }
        self.presentModal(vc, animated: true, completion: nil)
    }
    
    private func reloadPremiumCell() {
        if Settings.isPremium && self.cells.first! === self.premiumCell {
            self.cells.removeFirst().removeFromSuperview()
        }
        else if Settings.isPremium == false && self.cells.first! !== self.premiumCell {
            self.premiumCell.action = {
                [weak self] in
                guard let self = self else { return }
                self.didSelectOption(self.premiumCell)
            }
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
            self.presentModal(newProfileVC, animated: true, completion: nil)
        }
        else {
            showPremiumController()
        }
        
    }
    
    public func changeProfile(to profile: CDProfile?) {
        User.setActiveProfile(profile)
        
        if let container = self.presentingViewController as? AndanteViewController {
            container.didChangeProfile(profile)
        }
        
        UIView.transition(with: headerView, duration: 0.1, options: [.transitionCrossDissolve], animations: {
            self.headerView.profile = profile
        }, completion: nil)
    
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = min(140, scrollView.contentOffset.y)
        
        if offset < 0 {
            self.headerView.setOffset(0)
            self.headerView.frame = CGRect(
                x: 0, y: -offset,
                width: scrollView.bounds.width,
                height: 220)
        }
        else {
            self.headerView.setOffset(offset)
            self.headerView.frame = CGRect(
                x: 0, y: 0,
                width: scrollView.bounds.width,
                height: 220 - offset)
        }
        

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        scrollView.frame = self.view.bounds.inset(by: UIEdgeInsets(t: 70, l: 0, b: 0, r: 0))
                
        let offset = max(0, min(140, scrollView.contentOffset.y))
        self.headerView.frame = CGRect(
            x: 0, y: 0,
            width: scrollView.bounds.width,
            height: 220 - offset)
        
        let buttonWidth = self.view.bounds.width - Constants.margin*2
        changeProfileButton.frame = CGRect(
            x: self.view.bounds.midX - buttonWidth/2,
            y: 220 - 70,
            width: buttonWidth, height: 50)
        changeProfileButton.cornerRadius = 25
        
        let cellHeight: CGFloat = AndanteCellView.height
        let margin: CGFloat = 24
        
        var minY: CGFloat = changeProfileButton.frame.maxY + 20
        
        profilesLabel.sizeToFit()
        profilesLabel.frame.origin = CGPoint(x: margin, y: minY + 22)
        minY += profilesLabel.bounds.height + 8 + 22
        
        
        for cell in profileCells {
            cell.frame = CGRect(
                x: 0, y: minY,
                width: self.view.bounds.width,
                height: cellHeight)
            
            minY += cellHeight
        }
        
        toolsLabel.sizeToFit()
        toolsLabel.frame.origin = CGPoint(x: margin, y: minY + 22)
        minY += toolsLabel.bounds.height + 8 + 22
        
        let group1 = cells.contains(premiumCell) ? 4 : 3
        for i in 0..<group1 {
            cells[i].frame = CGRect(
                x: 0, y: minY,
                width: self.view.bounds.width,
                height: cellHeight)
            minY += cellHeight
        }
        
        helpLabel.sizeToFit()
        helpLabel.frame.origin = CGPoint(x: margin, y: minY + 22)
        minY += helpLabel.bounds.height + 8 + 22
        
        let group2 = 2
        for i in group1..<(group1+group2) {
            cells[i].frame = CGRect(
                x: 0, y: minY,
                width: self.view.bounds.width,
                height: cellHeight)
            minY += cellHeight
        }
        
        andanteLabel.sizeToFit()
        andanteLabel.frame.origin = CGPoint(x: margin, y: minY + 22)
        minY += andanteLabel.bounds.height + 8 + 22
        
        for i in (group1+group2)..<cells.count {
            cells[i].frame = CGRect(
                x: 0, y: minY,
                width: self.view.bounds.width,
                height: cellHeight)
            minY += cellHeight
        }
        
        versionLabel.frame = CGRect(
            x: self.view.bounds.midX - 50,
            y: minY + 24,
            width: 100,
            height: 32
        )
        
        scrollView.contentSize.height = versionLabel.frame.maxY + max(self.view.safeAreaInsets.bottom + 4, 24)
        
    }
    
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    
    func didSelectOption(_ option: AndanteCellView) {
        
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
        else if option == instagramCell {
            if let url = URL(string: "https://www.instagram.com/andante_practice_journal/") {
                UIApplication.shared.open(url)
            }
        }
        
    }
    
    func handleExport() {
        if Settings.isPremium {
            self.addChildTransitionController(ExportDataViewController())
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
        self.presentModal(vc, animated: true, completion: nil)
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

            self.presentModal(activityVC, animated: true, completion: nil)
        }
    }
    
    func handleMail() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.setToRecipients(["contact@andante.app"])
            mail.setSubject("Andante")
            mail.mailComposeDelegate = self
            self.presentModal(mail, animated: true, completion: nil)

        } else {
            let alert = ActionTrayPopupViewController(title: "Can't send mail", description: "Your device isn't configured to automatically send emails. Try copying the address instead!")
            
            alert.addAction("Copy Email") {
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


//MARK: - Header

class SettingsHeaderView: UIView {
    
    private let activeProfileIcon = MultipleProfilesView()
    private let activeProfileLabel = LabelGroup()
    private let separator = Separator(position: .bottom)
    
    private var cancellables = Set<AnyCancellable>()
    
    public var profile: CDProfile? {
        didSet {
            cancellables.removeAll()
            if let profile = profile {
                self.activeProfileIcon.setProfiles([profile])
                profile.publisher(for: \.name).sink {
                    [weak self] name in
                    guard let self = self else { return }
                    self.activeProfileLabel.titleLabel.text = name
                    self.setNeedsLayout()
                }.store(in: &cancellables)
                
                profile.publisher(for: \.sessions).sink {
                    [weak self] sessions in
                    guard let self = self else { return }
                    self.activeProfileLabel.detailLabel.text = Formatter.formatSessionCount(sessions?.count)
                    self.setNeedsLayout()
                }.store(in: &cancellables)
            }
            else {
                self.activeProfileIcon.setProfiles(CDProfile.getAllProfiles())
                self.activeProfileLabel.titleLabel.text = "All Profiles"
                self.activeProfileLabel.detailLabel.text = Formatter.formatSessionCount(PracticeDatabase.shared.sessions().count)
            }
            
            self.setNeedsLayout()
            
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = Colors.foregroundColor
        
        defer {
            self.profile = User.getActiveProfile()
        }
        
        activeProfileIcon.isUserInteractionEnabled = false
        activeProfileIcon.containerBackgroundColor = Colors.foregroundColor
        activeProfileIcon.profileInsets = 4
        self.addSubview(activeProfileIcon)
        
        activeProfileLabel.titleLabel.textColor = Colors.text
        activeProfileLabel.titleLabel.font = Fonts.bold.withSize(21)
        activeProfileLabel.detailLabel.textColor = Colors.lightText
        activeProfileLabel.detailLabel.font = Fonts.medium.withSize(15)
        activeProfileLabel.padding = 6
        activeProfileLabel.textAlignment = .center
        self.addSubview(activeProfileLabel)
        
        self.separator.alpha = 0
        self.separator.inset = .zero
        self.addSubview(self.separator)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public func setOffset(_ offset: CGFloat) {
        let progress = min(1, offset / 140)
        print(offset, progress)
        self.activeProfileIcon.transform = {
            let size = 94 - offset
            let scale = max(0, size / 94)
            let translation = (94 - 94*scale)/2
            return CGAffineTransform(scaleX: scale, y: scale).concatenating(CGAffineTransform(translationX: 0, y: -translation))
        }()

        let maxTitleOffset: CGFloat = 116
        let scale = 1 - (0.15 * progress)
        if offset > maxTitleOffset {
            self.activeProfileLabel.transform = CGAffineTransform(translationX: 0, y: offset - maxTitleOffset).concatenating(CGAffineTransform(scaleX: scale, y: scale))
        }
        else {
            self.activeProfileLabel.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
        
        if progress > 0.75 {
            separator.alpha = (progress - 0.75) / 0.25
        } else {
            separator.alpha = 0
        }
        
        self.activeProfileIcon.alpha = 1 - progress*2
        self.activeProfileLabel.detailLabel.alpha = 1 - progress*2
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.separator.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 80)
        
        activeProfileIcon.bounds.size.height = 96
        activeProfileIcon.bounds.size.width = activeProfileIcon.calculateWidth()
        activeProfileIcon.center = CGPoint(x: self.bounds.midX, y: 40 + (96/2))
        
        let height = activeProfileLabel.sizeThatFits(self.bounds.size).height
        activeProfileLabel.contextualFrame = CGRect(x: 40, y: self.bounds.maxY - height - 20,
                                             width: self.bounds.width - 80,
                                             height: height)
        
        
    }
}

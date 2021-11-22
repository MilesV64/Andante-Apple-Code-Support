//
//  AndanteViewController.swift
//  Andante
//
//  Created by Miles Vinson on 11/1/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit
import Combine
import CoreData
import AVFoundation
import StoreKit

extension UIView {
    enum NavigationStyle {
        case tabbar, sidebar
    }
    
    var globalNavigationStyle: NavigationStyle {
        if let window = UIApplication.shared.windows.first {
            return window.bounds.width > Constants.sidebarBreakpoint ? .sidebar : .tabbar
        } else {
            return .tabbar
        }
    }
    
    func headerHeight(matching navigationStyle: NavigationStyle) -> CGFloat {
        return navigationStyle == .tabbar ? 44 : 60
    }
    
}

class AndanteViewController: NavigationViewController, NavigationComponentDelegate, ProfileObserver {
    
    //bc of the safe area insets changing for no reason when transformed 🙄
    public var contentView = TransformIgnoringSafeAreaInsetsView()

    //MARK: - Navigation

    public var sessionsViewController = SessionsViewController()
    private var sessionsTabPresentedVC: NavigatableViewController?
    
    public var statsViewController = StatsViewController()
    private var statsTabPresentedVC: NavigatableViewController?
    
    public var journalViewController = JournalViewController()
    private var journalTabPresentedVC: NavigatableViewController?
    
    private var activeViewController: MainViewController!
    private var activeIndex: Int = 0
    private var viewControllers: [MainViewController] = []
    private var contentFrame = CGRect()

    private var sidebar: Sidebar?
    public var tabbar: Tabbar?
    private var activeNavComponent: NavigationComponent!
    
    public var isSidebarEnabled = false
    
    //MARK: - Other
    
    public var collapsedSessionView: CollapsedSessionView?

    //for extra transform
    private let actionButtonView = UIView()
    public let actionButton = ActionButton()
    private let actionButtonIcon = IconView()
    private let actionButtonFeedback = UIImpactFeedbackGenerator(style: .light)

    private var sessionSaveNotification: SessionSaveNotification?
    private var sessionSaveNotificationTimer: Timer?
    private var lastSession: CDSession?

    private var currentDay: Day?
    
    private var profileCancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .black
        view.addSubview(contentView)

        contentView.backgroundColor = Colors.backgroundColor
        
        contentView.addSubview(self.navigationContentView)

        viewControllers = [
            sessionsViewController,
            statsViewController,
            journalViewController
        ]
        
        viewControllers.forEach { $0.containerViewController = self }
        
        selectViewController(0)

        setupActionButton()

        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)

        ProfileManager.shared.addObserver(self)
        
        let today = Day(date: Date())
        let nextDate = today.nextDay().date
        let timer = Timer(fireAt: nextDate, interval: 0, target: self, selector: #selector(didChangeDay), userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
        
    }
    
    func navigationComponentDidSelect(index: Int) {
        if index >= 2 {
            if isSidebarEnabled {
                guard let profile = User.getActiveProfile() else { return }
                User.setActiveFolder(profile.getJournalFolders()[index-2])
                journalViewController.setActiveFolder()
            }
            selectViewController(index)
        }
        
        else {
            selectViewController(index)
        }
        
    }
    
    

    private func selectViewController(_ index: Int) {
        if activeIndex == index && activeViewController != nil {
            activeViewController.pageReselected()
            sidebar?.setSelectedTab(index)
            tabbar?.setSelectedTab(index)
            return
        }
        
        let viewController: MainViewController
        switch index {
        case 0: viewController = sessionsViewController
        case 1: viewController = statsViewController
        default: viewController = journalViewController
        }
        
        
        // - Pop navigated VC for old tab
        if let presentedVC = self.navigatedViewController {
//            if self.activeIndex == 0 {
//                self.sessionsTabPresentedVC = presentedVC
//            }
//            else if self.activeIndex == 1 {
//                self.statsTabPresentedVC = presentedVC
//            }
            self.pop(animated: false)
        }
        
//        // - Present navigated VC for new tab
//        switch index {
//        case 0:
//            if let presentedVC = self.sessionsTabPresentedVC {
//                self.push(presentedVC, animated: false)
//                self.sessionsTabPresentedVC = nil
//            }
//        case 1:
//            if let presentedVC = self.statsTabPresentedVC {
//                self.push(presentedVC, animated: false)
//                self.statsTabPresentedVC = nil
//            }
//        default:
//            // Push the
//            break
//        }
        
                
        if index >= 2 && activeIndex >= 2 {
            activeIndex = index
            sidebar?.setSelectedTab(index)
            tabbar?.setSelectedTab(index)
            return
        }
        else {
            if activeViewController != nil {
                activeViewController.willMove(toParent: nil)
                activeViewController.view.removeFromSuperview()
                activeViewController.removeFromParent()
            }
            
            addChild(viewController)
            navigationContentView.insertSubview(viewController.view, belowSubview: self.actionButtonView)
            viewController.didMove(toParent: self)
            
            if self.activeViewController != nil {
                viewController.mainHeaderView.streakAnimationFrame = activeViewController.mainHeaderView.streakAnimationFrame
            }
            
            activeViewController = viewController
            view.setNeedsLayout()
        }
        
        if index == 0 {
            if collapsedSessionView == nil {
                if activeIndex >= 2 {
                    bounceactionButton(tab: 0)
                }
                else {
                    showactionButton(tab: 0)
                }
            } else {
                hideactionButton()
            }
        }
        else if index == 1 {
            hideactionButton()
        }
        else if index >= 2 {
            if activeIndex == 0 && collapsedSessionView == nil {
                bounceactionButton(tab: 2)
            }
            else {
                showactionButton(tab: 2)
            }
        }
        
        activeIndex = index
        sidebar?.setSelectedTab(index)
        tabbar?.setSelectedTab(index)
        
    }
    
    private func setNavigationComponents() {
        if self.view.bounds.width > Constants.sidebarBreakpoint {
            if sidebar == nil {
                sidebar = Sidebar(self.activeIndex)
                sidebar!.delegate = self
                contentView.addSubview(sidebar!)
            }
            tabbar?.removeFromSuperview()
            tabbar = nil
            self.activeNavComponent = sidebar
            isSidebarEnabled = true
        }
        else {
            if tabbar == nil {
                tabbar = Tabbar(self.activeIndex)
                tabbar!.delegate = self
                
                if let collapsedView = self.collapsedSessionView {
                    navigationContentView.insertSubview(tabbar!, aboveSubview: collapsedView)
                } else {
                    navigationContentView.insertSubview(tabbar!, aboveSubview: actionButtonView)
                }
            }
            sidebar?.removeFromSuperview()
            sidebar = nil
            self.activeNavComponent = tabbar
            isSidebarEnabled = false
        }
    }
    
    func presentingViewController() -> AndanteViewController {
        return self
    }
    
    func didDeleteFolder(wasActive: Bool) {
        if wasActive {
            selectViewController(2)
        } else {
            selectViewController(activeIndex)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.userInterfaceStyle == .dark {
            actionButton.buttonView.layer.shadowOpacity = 0.3
        }
        else {
            actionButton.buttonView.layer.shadowOpacity = 0.18
        }

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        contentView.contextualFrame = self.view.bounds
        
        setNavigationComponents()

        layoutNavigation()
        
        layoutActionButton()
        
        layoutSaveNotification()

    }

    public func animate() {
        UIView.animate(withDuration: ToolTips.didShowSessionsTooltip ? 0.3 : 0) {
            self.actionButtonView.alpha = 1
        }
        
        if UserVersion.shouldShowWhatsNew {
            UserVersion.shouldShowWhatsNew = false
            
            self.sessionsViewController.animate(true)
            
            let whatsNew = WhatsNewViewController()
            
            whatsNew.closeAction = {
                self.sessionsViewController.showTooltip(nil)
                if CDOngoingSession.ongoingSession != nil {
                    self.presentResumeSessionAlert()
                }
            }

            self.presentModal(whatsNew, animated: true, completion: nil)
        }
        else {
            self.sessionsViewController.animate()
            
            if CDOngoingSession.ongoingSession != nil {
                self.presentResumeSessionAlert()
            }
        }
        
    }
    
    func navigationComponentDidRequestChangeProfile(
        sourceView: UIView,
        sourceRect: CGRect,
        arrowDirection: UIPopoverArrowDirection
    ) {
        if CDProfile.getAllProfiles().count > 1 {
            let changeProfileAlert = ProfilesPopupViewController()
            changeProfileAlert.selectedProfile = User.getActiveProfile()
            changeProfileAlert.action = {
                [weak self] profile in
                guard let self = self else { return }
                User.setActiveProfile(profile)
                self.didChangeProfile(profile)
            }
            
            changeProfileAlert.newProfileAction = {
                [weak self] in
                guard let self = self else { return }
                changeProfileAlert.closeCompletion = {
                    [weak self] in
                    guard let self = self else { return }
                    self.newProfile()
                }
                changeProfileAlert.close()
            }
            
            self.presentPopupViewController(changeProfileAlert)
           
        }
        else {
            let alert = ActionTrayPopupViewController(title: "You only have one profile!", description: "Use multiple profiles to conveniently track your progress with every art, skill, and craft you're practicing.")
            
            alert.addAction("New Profile") { [weak self] in
                self?.newProfile()
            }
            
            self.presentPopupViewController(alert)
        }
    }
    
    private func newProfile() {
        if Settings.isPremium {
            let newProfileVC = CreateProfileViewController()
            newProfileVC.modalPresentationStyle = .formSheet
            newProfileVC.preferredContentSize = Constants.modalSize
            newProfileVC.handler = {
                [weak self] profile in
                guard let self = self else { return }
                CDProfile.saveProfile(profile)
                User.setActiveProfile(profile)
                User.reloadData()
                self.didChangeProfile(profile)
            }
            self.presentModal(newProfileVC, animated: true, completion: nil)
        }
        else {
            self.presentModal(AndanteProViewController(), animated: true, completion: nil)
        }
        
    }
    
    private func presentResumeSessionAlert() {
        let alert = ActionTrayPopupViewController(
            title: "Resume Session?",
            description: "The app was terminated while a session was in progress."
        )
        
        alert.addAction("Resume Session") { [weak self] in
            self?.startPracticeSession(animated: true)
        }
        
        alert.cancelAction = {
            CDOngoingSession.deleteOngoingSession()
        }
        
        self.presentPopupViewController(alert)
        
    }

    @objc func didChangeDay() {
        checkDay()

        let today = Day(date: Date())
        let nextDate = today.nextDay().date
        let timer = Timer(fireAt: nextDate, interval: 0, target: self, selector: #selector(didChangeDay), userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
    }

    @objc func didBecomeActive() {
        checkDay()
    }

    private func checkDay() {
        if let currentDay = self.currentDay {
            let day = Day(date: Date())
            if day != currentDay {
                self.currentDay = day
                PracticeDatabase.shared.reloadStreak()
                for vc in self.viewControllers {
                    vc.dayDidChange()
                }
            }
        }
        else {
            currentDay = Day(date: Date())
        }
    }

}

//MARK: Layouts
extension AndanteViewController {

    private func layoutNavigation() {

        if !isSidebarEnabled {
            if let tabbar = self.tabbar {
                
                navigationContentView.contextualFrame = self.view.bounds
                
                if tabbar.superview == navigationContentView {
                    //dont edit frame if the tabbar is added to practice view controller for animation
                    tabbar.frame = CGRect(
                        from: CGPoint(x: 0, y: self.navigationContentView.bounds.maxY - self.view.safeAreaInsets.bottom - 49),
                        to: CGPoint(x: navigationContentView.bounds.maxX, y: navigationContentView.bounds.maxY))
                }
                
                var collapsedMinY: CGFloat?
                if let collapsedSessionView = self.collapsedSessionView {
                    if collapsedSessionView.superview == navigationContentView {
                        collapsedSessionView.frame = CGRect(
                            x: 0,
                            y: self.navigationContentView.bounds.maxY - self.view.safeAreaInsets.bottom - 49 - 54,
                            width: tabbar.bounds.width,
                            height: collapsedSessionView.bounds.height)
                        collapsedMinY = collapsedSessionView.frame.minY
                    }
                }
                
                contentFrame = CGRect(
                    from: CGPoint(x: 0, y: 0),
                    to: CGPoint(x: navigationContentView.bounds.width, y: collapsedMinY ?? tabbar.frame.minY))
            }
        }
        else {
            let width: CGFloat = min(view.bounds.width/3, 300)
            if let sidebar = self.sidebar {
                sidebar.frame = CGRect(
                    from: CGPoint(x: 0, y: 0),
                    to: CGPoint(x: width, y: view.bounds.maxY))
                
                navigationContentView.contextualFrame = CGRect(
                    from: CGPoint(x: sidebar.frame.maxX, y: 0),
                    to: CGPoint(
                        x: view.bounds.maxX,
                        y: view.bounds.maxY))
                
                collapsedSessionView?.frame = CGRect(
                    x: 0, y: navigationContentView.bounds.maxY - view.safeAreaInsets.bottom - 54,
                    width: navigationContentView.bounds.width, height: 54 + view.safeAreaInsets.bottom)
                
                contentFrame = CGRect(
                    from: CGPoint(x: 0, y: 0),
                    to: CGPoint(
                        x: navigationContentView.bounds.maxX,
                        y: collapsedSessionView?.frame.minY ?? navigationContentView.bounds.maxY))
            }
        }
        
        activeViewController?.view.frame = contentFrame
    }
    
    private func layoutActionButton() {
        if !isSidebarEnabled {
            let frame = contentFrame
            
            let rect = CGRect(x: frame.maxX - 56 - 14,
                              y: frame.maxY - 14 - 56,
                              width: 56, height: 56)
            actionButtonView.bounds.size = rect.size
            actionButtonView.center = CGPoint(x: rect.midX, y: rect.midY)
        }
        else {
            let space: CGFloat = max(view.safeAreaInsets.bottom, 20)
            let rect = CGRect(x: contentFrame.maxX - 14 - 62,
                              y: contentFrame.maxY - space - 62,
                              width: 62, height: 62)
            
            actionButtonView.bounds.size = rect.size
            actionButtonView.center = CGPoint(x: rect.midX, y: rect.midY)
        }
        
        
        actionButton.bounds.size = actionButtonView.bounds.size
        actionButton.center = actionButtonView.bounds.center
        
        actionButtonIcon.bounds.size = actionButton.bounds.size
        actionButtonIcon.center = actionButton.bounds.center
        
        actionButton.cornerRadius = actionButton.bounds.height/2
                
    }
    
    private func layoutSaveNotification() {
        
        let alertHeight: CGFloat = 58

        
        if traitCollection.horizontalSizeClass == .compact {
            let tabHeight: CGFloat = 49
            let margin: CGFloat = 10
            let rect = CGRect(
                x: margin,
                y: self.view.bounds.maxY - self.view.safeAreaInsets.bottom - tabHeight - margin - alertHeight,
                width: self.view.bounds.width - margin*2, height: alertHeight)
            
            sessionSaveNotification?.bounds.size = rect.size
            sessionSaveNotification?.center = CGPoint(x: rect.midX, y: rect.midY)
        }
        else {
            var maxY: CGFloat
            if isSidebarEnabled {
                maxY = view.bounds.maxY - max(view.safeAreaInsets.bottom, 20) - 2
            }
            else {
                maxY = contentFrame.maxY - 14 + 1
            }
            
            sessionSaveNotification?.bounds.size = CGSize(width: 420, height: alertHeight)
            sessionSaveNotification?.center = CGPoint(x: view.bounds.midX, y: maxY - alertHeight/2)
            
        }
        
        
    }

}

//MARK: - Action button
extension AndanteViewController {

    func setupActionButton() {
        self.navigationContentView.addSubview(actionButtonView)
        actionButtonView.backgroundColor = .clear
        actionButtonView.addSubview(actionButton)
        actionButton.backgroundColor = Colors.orange
        actionButton.buttonView.setShadow(radius: 6, yOffset: 3, opacity: 0.18)
        if view.traitCollection.userInterfaceStyle == .dark {
            actionButton.buttonView.layer.shadowOpacity = 0.3
        }
        else {
            actionButton.buttonView.layer.shadowOpacity = 0.18
        }
        self.actionButtonView.alpha = 0

        setSessionsButton()
        actionButton.addSubview(actionButtonIcon)

        actionButton.setCompletion({
            self.actionButtonFeedback.impactOccurred()
            if self.activeIndex == 0 {
                self.startPracticeSession(animated: true)
            }
            else if self.activeIndex >= 2 {
                self.journalViewController.newEntry()
            }
        })

        actionButton.longPressCompletion = {
            let vc = ManualSessionViewController()
            self.presentModal(vc, animated: true, completion: nil)
        }

        actionButtonFeedback.prepare()
    }

    public func hideactionButton(animated: Bool = true) {
        UIView.animate(withDuration: animated ? 0.1 : 0) {
            self.actionButtonView.alpha = 0
            self.actionButton.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }
    }

    public func showactionButton(tab: Int) {        
        tab == 0 ? setSessionsButton() : setJournalButton()
        view.setNeedsLayout()
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.actionButtonView.alpha = 1
            self.actionButton.transform = .identity
        }, completion: nil)
    }

    public func setSessionsButton() {
        self.actionButtonIcon.icon = UIImage(named: "music.plus")
        self.actionButtonIcon.iconColor = Colors.white
        actionButton.canLongPress = true
    }

    public func setJournalButton() {
        self.actionButtonIcon.icon = UIImage(named: "journal.plus")
        self.actionButtonIcon.iconColor = Colors.white
        actionButton.canLongPress = false
    }

    public func bounceactionButton(tab: Int) {

        tab == 0 ? setSessionsButton() : setJournalButton()

        if actionButtonView.alpha == 0 {
            showactionButton(tab: 2)
        }
        else {
            UIView.animate(withDuration: 0.1, animations: {
                self.actionButton.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
            }) { (complete) in
                UIView.animate(withDuration: 0.2, animations: {
                    self.actionButton.transform = .identity
                }, completion: nil)
            }
        }
        
    }

}

//MARK: - Session notification
extension AndanteViewController {
    private func showSessionSaveNotification(delay: Bool = true) {
        guard let lastSession = lastSession else { return }
        
        let context = DataManager.context
        guard let session = try? context.existingObject(with: lastSession.objectID) as? CDSession else {
            return
        }

        if self.sessionSaveNotification != nil {
            self.sessionSaveNotification?.removeFromSuperview()
            self.sessionSaveNotification = nil
            self.sessionSaveNotificationTimer?.invalidate()
            self.sessionSaveNotificationTimer = nil
        }

        sessionSaveNotification = SessionSaveNotification()
        sessionSaveNotification?.action = {
            [weak self] in
            guard let self = self else { return }

            let detailVC = SessionDetailViewController(session: session, indexPath: nil)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.sessionSaveNotificationTimer?.invalidate()
                self.sessionSaveNotificationTimer = nil
                self.hideSessionSaveNotification()
            }
            
            self.push(detailVC)
        }

        self.contentView.addSubview(sessionSaveNotification!)
        layoutSaveNotification()

        sessionSaveNotification?.trigger(session)
        sessionSaveNotification?.transform = CGAffineTransform(translationX: 0, y: self.view.safeAreaInsets.bottom + 110)

        UIView.animate(withDuration: 0.6, delay: delay ? 0.3 : 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.sessionSaveNotification?.transform = .identity
            if self.traitCollection.horizontalSizeClass == .compact {
                self.actionButtonView.transform = CGAffineTransform(translationX: 0, y: -54-10)
            }
        }, completion: nil)

        sessionSaveNotificationTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false, block: {
            [weak self] timer in
            guard let self = self else { return }

            self.hideSessionSaveNotification()
        })

        RunLoop.current.add(sessionSaveNotificationTimer!, forMode: .common)

    }

    private func hideSessionSaveNotification() {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
            self.sessionSaveNotification?.transform = CGAffineTransform(translationX: 0, y: 140)
        }, completion: { complete in
            self.sessionSaveNotification?.removeFromSuperview()
            self.sessionSaveNotification = nil
        })

        UIView.animate(withDuration: 0.55, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.actionButtonView.transform = .identity
        }, completion: nil)
    }
}

//MARK: - Add/delete sessions, change profile
extension AndanteViewController {
    
    public func savePracticeSession(_ model: SessionModel) {
        let profile = model.profile ?? User.getActiveProfile()
        guard let profileID = profile?.objectID else { return }
        
        let context = DataManager.backgroundContext
        
        let session = CDSession(context: context)
        try? context.obtainPermanentIDs(for: [session])
        
        session.createSession(
            begin: model.start,
            end: model.end ?? Date(),
            practiceTime: model.practiceTime,
            mood: model.mood,
            focus: model.focus,
            notes: model.notes,
            title: model.title)
        
        for (i, data) in model.recordings.enumerated() {
            let recording = CDRecording(context: context)
            recording.index = Int64(i)
            recording.recordingData = data
            session.addToRecordings(recording)
        }
        
        let request = CDProfile.fetchRequest() as NSFetchRequest<CDProfile>
        request.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        if
            let profiles = try? context.fetch(request),
            let profile = profiles.first(where: { $0.objectID == profileID })
        {
            profile.addToSessions(session)
        }
        
        try? context.save()
        
        lastSession = session
        showSessionSaveNotification(delay: true)
        
        // Ask for rating
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            CDAskForRatingTracker.askForRating()
        }
        
    }
    
    public func didChangeProfile(_ profile: CDProfile?) {
        sidebar?.reloadData()
        
        for vc in self.viewControllers {
            vc.didChangeProfile(profile: profile)
            if vc == self.activeViewController {
                vc.viewWillAppear(false)
            }
        }
        
    }
    
    func profileManager(_ profileManager: ProfileManager, didDeleteProfile profile: CDProfile) {
        let didDeleteActiveProfile = profile == User.getActiveProfile()
        let isAllProfilesSelected = User.getActiveProfile() == nil
        let currentProfileCount = CDProfile.getAllProfiles().count
        
        if didDeleteActiveProfile || (isAllProfilesSelected && currentProfileCount == 1)  {
            if let first = CDProfile.getAllProfiles().first {
                User.setActiveProfile(first)
                if let settingsContainer = self.presentedViewController as? SettingsContainerViewController {
                    settingsContainer.settingsViewController?.changeProfile(to: first)
                }
                else {
                    self.closeViewControllers {
                        self.didChangeProfile(first)
                    }
                }
            }
            else {
                // we're in trouble
            }
        }
    }
    
}

//MARK: Practice
extension AndanteViewController: CollapsedSessionViewDelegate {
    
    public var isPracticing: Bool {
        if let _ = self.presentedViewController as? PracticeViewController {
            return true
        }
        else if collapsedSessionView != nil {
            return true
        }
        else {
            return false
        }
    }
    
    @objc func startPracticeSession(animated: Bool) {
        
        let practiceController = PracticeViewController()
        self.present(practiceController, animated: animated, completion: nil)
        
        self.setupIntentsForSiri()
        
    }
    
    func setupIntentsForSiri() {
        if let activity = User.getActiveProfile()?.getSiriActivity() {
            view.userActivity = activity
            activity.becomeCurrent()
        }
    }
    
    func collapsedSessionDidTapExpand() {
        if let practiceController = collapsedSessionView?.practiceViewController {
            self.present(practiceController, animated: true, completion: {
                if self.activeIndex == 0 {
                    self.showactionButton(tab: 0)
                }
            })
        }
        
    }
    
    func showCollapsedSessionView(_ sessionView: CollapsedSessionView) {
        self.collapsedSessionView = sessionView
        sessionView.delegate = self
        self.navigationContentView.addSubview(sessionView)
        
        if activeIndex == 0 {
            hideactionButton()
        }
    }
}

//MARK: Journal
extension AndanteViewController {
    
    func sidebarDidSelectNewFolder() {
        if Settings.isPremium {
            let newFolderAlert = NewFolderCenterAlertController(animateWithKeyboard: true)
            newFolderAlert.confirmAction = {
                [weak self] in
                guard let self = self else { return }
                
                if let title = newFolderAlert.textField.text {
                    let folder = CDJournalFolder(context: DataManager.context)
                    DataManager.obtainPermanentID(for: folder)
                    folder.title = title
                    
                    if let profile = User.getActiveProfile() {
                        var folders = profile.getJournalFolders()
                        folders.append(folder)
                        
                        profile.addToJournalFolders(folder)
                        profile.updateFolderOrder(toMatch: folders)
                        
                        DataManager.saveContext()
                        
                    }
                    
                }
            }
            
            self.present(newFolderAlert, animated: false, completion: nil)
        }
        else {
            self.presentModal(AndanteProViewController(), animated: true, completion: nil)
        }
    }
    
    func sidebarNeedsReload() {
        sidebar?.reloadData()
    }
    
}

//MARK: Siri start, change profile
extension AndanteViewController {
    
    private func closeViewControllers(_ completion: (()->Void)?) {
        
        if let _ = self.presentedViewController as? PracticeViewController {
            return
        }
        
        if let vc = self.presentedViewController {
            if let vc = vc as? TransitionViewController {
                vc.close(animated: false, completion: {
                    self.closeViewControllers(completion)
                })
            }
            else {
                vc.dismiss(animated: false, completion: {
                    self.closeViewControllers(completion)
                })
            }
        }
        else {
            completion?()
        }
    }
    
    public func changeProfileFromWidget(to profile: CDProfile) {
        if self.presentedViewController == nil {
            User.setActiveProfile(profile)
            self.didChangeProfile(profile)
        }
    }
    
    public func handleSiriStart(profile: CDProfile, completion: (()->Void)?) {
        closeViewControllers {
            //TODO i dont think tab highlights correctly
            
            User.setActiveProfile(profile)
            self.didChangeProfile(profile)

            self.startPracticeSession(animated: false)
            
            completion?()
        }
        
    }
    
}

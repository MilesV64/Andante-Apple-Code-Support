//
//  Sidebar.swift
//  Andante
//
//  Created by Miles Vinson on 11/2/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class Sidebar: NavigationComponent, SidebarFoldersDelegate, PracticeDatabaseObserver {
    
    private let scrollView = CancelTouchScrollView()
    private let separator = UIView()
    
    private let sessionsTab = TabView(.sessions)
    private let statsTab = TabView(.stats)
    private let journalHeader = JournalTabHeader()
    
    private var foldersView = SidebarFoldersView()
    
    private let streakView = StreakView()
    private let profileView = MultipleProfilesView()
    
    private var profile: CDProfile?
    
    func presentationViewController() -> UIViewController? {
        return delegate?.presentingViewController()
    }
        
    init(_ selectedTab: Int = 0) {
        super.init(frame: .zero)
        
        if selectedTab == 2 {
            if let profile = User.getActiveProfile(), let activeFolder = User.getActiveFolder(for: profile) {
                self.activeIndex = 2 + Int(activeFolder.index)
            } else {
                self.activeIndex = 2
            }
        }
        else {
            self.activeIndex = selectedTab
        }
        
        
        self.backgroundColor = Colors.barColor
        
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = Colors.barColor
        self.addSubview(scrollView)
        
        separator.backgroundColor = Colors.separatorColor
        self.addSubview(separator)
        
        scrollView.addSubview(streakView)
        
        profileView.containerBackgroundColor = Colors.foregroundColor
        profileView.action = {
            [weak self] in
            guard let self = self else { return }
            let vc = SettingsContainerViewController()
            self.delegate?.presentingViewController().presentModal(vc, animated: true, completion: nil)
        }
        scrollView.addSubview(profileView)
        
        [sessionsTab, statsTab].enumerated().forEach { (i, tab) in
            tab.action = {
                [weak self] in
                guard let self = self else { return }
                self.setSelectedTab(i)
                self.delegate?.navigationComponentDidSelect(index: i)
            }
            scrollView.addSubview(tab)
            
            tab.setSelected(i == selectedTab)
        }
        
        scrollView.addSubview(journalHeader)
        
        foldersView.delegate = self
        scrollView.addSubview(foldersView)
        
        PracticeDatabase.shared.addObserver(self)
        
        reloadData()
        
        //TODO animate folders layout when folder added/removed
        
    }
    
    // MARK: - PracticeDatabaseObserver
    
    func practiceDatabaseDidUpdate(_ practiceDatabase: PracticeDatabase) {}
    func practiceDatabase(_ practiceDatabase: PracticeDatabase, didChangeFor profile: CDProfile) {}
    
    func practiceDatabase(_ practiceDatabase: PracticeDatabase, didChangeTotalStreak streak: Int) {
        if self.profile == nil {
            self.reloadStreak()
        }
    }
    
    func practiceDatabase(_ practiceDatabase: PracticeDatabase, streakDidChangeFor profile: CDProfile, streak: Int) {
        if profile == self.profile {
            self.reloadStreak()
        }
    }
    
    @objc func reloadStreak() {
        self.streakView.streak = PracticeDatabase.shared.streak(for: User.getActiveProfile())
        self.setNeedsLayout()
    }
    
    public func reloadData() {
        self.profile = User.getActiveProfile()
        
        if let profile = profile {
            profileView.setProfiles([profile])
        } else {
            profileView.setProfiles(CDProfile.getAllProfiles())
        }
        
        reloadStreak()
        
        setFolders()
        
    }
    
    private func setFolders() {
        guard let profile = User.getActiveProfile() else { return }
        
        foldersView.setProfile(profile, selectedIndex: activeIndex - 2)
        
        setNeedsLayout()
        
    }
    
    override func setSelectedTab(_ index: Int) {
        self.activeIndex = index
        
        [sessionsTab, statsTab].enumerated().forEach { (i, tab) in
            tab.setSelected(i == index)
        }
        
        if index >= 2 {
            foldersView.setSelectedFolder(index: index - 2)
        } else {
            foldersView.setSelectedFolder(index: nil)
        }
        
    }
    
    func needsActiveIndexUpdate() {
        if activeIndex >= 2 {
            if let profile = User.getActiveProfile(), let activeFolder = User.getActiveFolder(for: profile) {
                self.activeIndex = 2 + Int(activeFolder.index)
            } else {
                self.activeIndex = 2
            }
        }
    }
    
    func didSelectFolder(_ folder: CDJournalFolder, at index: Int) {
        self.delegate?.navigationComponentDidSelect(index: index + 2)
        setSelectedTab(index + 2)
        activeIndex = index + 2
        setNeedsLayout()
    }
    
    func foldersDidUpdate(_ activeFolderIndex: Int?, firstUpdate: Bool) {
        
        if let index = activeFolderIndex {
            
            if self.activeIndex >= 2 {
                self.activeIndex = 2 + index
                foldersView.setSelectedFolder(index: index)
            }
            
        }
        
        if !firstUpdate {
            setNeedsLayout()
        }
        
    }
    
    func didSelectNewFolder() {
        delegate?.sidebarDidSelectNewFolder()
    }
    
    func needsLayoutUpdate() {
        setNeedsLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let insets = UIApplication.shared.windows.first?.safeAreaInsets ?? safeAreaInsets
        
        separator.frame = CGRect(
            x: bounds.maxX - 1, y: 0,
            width: 1, height: bounds.height)
        
        scrollView.frame = self.bounds.inset(by: UIEdgeInsets(top: insets.top, left: 0, bottom: 0, right: 0))
                
        let profileSize: CGFloat = 46
        profileView.bounds.size.height = profileSize
        let profileWidth = profileView.calculateWidth()
        profileView.frame = CGRect(x: Constants.smallMargin, y: 30 - profileSize/2,
            width: profileWidth, height: profileSize).integral
        
        self.streakView.sizeToFit()
        streakView.frame = CGRect(
            x: self.bounds.maxX - self.streakView.bounds.width - Constants.smallMargin,
            y: 30 - self.streakView.bounds.height/2,
            width: self.streakView.bounds.width, height: self.streakView.bounds.height)
        
        let tabWidth: CGFloat = bounds.width - Constants.smallMargin*2
        let tabHeight: CGFloat = 48
        let tabSpacing: CGFloat = 8
        
        [sessionsTab, statsTab].enumerated().forEach { (i, tab) in
            tab.frame = CGRect(
                x: Constants.smallMargin,
                y: profileView.frame.maxY + 32 + CGFloat(i)*(tabHeight + tabSpacing),
                width: tabWidth,
                height: tabHeight)
        }
        
        journalHeader.frame = CGRect(
            x: Constants.smallMargin,
            y: statsTab.frame.maxY,
            width: tabWidth,
            height: 38)
        
        let height = foldersView.sizeThatFits(self.bounds.size).height
        foldersView.frame = CGRect(
            x: 0,
            y: journalHeader.frame.maxY,
            width: self.bounds.width,
            height: height)
        
        scrollView.contentSize.height = foldersView.frame.maxY + 50
        
    }
}

fileprivate class TabView: CustomButton {
    
    private var isSelectedTab = false
    
    init(_ tab: NavigationComponent.Tab) {
        super.init()
        
        self.roundCorners(12)
        
        if tab == .journal {
            self.setImage(UIImage(name: "folder.fill", pointSize: 19, weight: .medium)?.withRenderingMode(.alwaysTemplate), for: .normal)
            contentEdgeInsets.left = 14
            imageEdgeInsets.bottom = 2
            titleEdgeInsets.left = 13
        }
        else {
            self.setImage(tab.icon?.withRenderingMode(.alwaysTemplate), for: .normal)
            contentEdgeInsets.left = 16
            imageEdgeInsets.bottom = 2
            titleEdgeInsets.left = 14
        }
        self.adjustsImageWhenHighlighted = false
    
        self.setTitle(tab.string, for: .normal)
        
        contentHorizontalAlignment = .left
        
        
        
        self.highlightAction = {
            [weak self] highlighted in
            guard let self = self else { return }
            if highlighted && !self.isSelectedTab {
                self.backgroundColor = Colors.lightColor
            } else {
                if !self.isSelectedTab {
                    UIView.animate(withDuration: 0.3) {
                        self.backgroundColor = .clear
                    }
                }
            }
        }
    }
    
    public func setSelected(_ selected: Bool) {
        self.isSelectedTab = selected
        
        if selected {
            self.backgroundColor = Colors.orange
            self.setTitleColor(Colors.white, for: .normal)
            self.titleLabel?.font = Fonts.medium.withSize(17)
            self.tintColor = Colors.white
            self.tintAdjustmentMode = .normal
        }
        else {
            self.backgroundColor = .clear
            self.setTitleColor(Colors.text, for: .normal)
            self.titleLabel?.font = Fonts.medium.withSize(17)
            self.tintColor = Colors.orange
            self.tintAdjustmentMode = .automatic
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
}

fileprivate class NewFolderButton: CustomButton {
        
    override init() {
        super.init()
                
        self.setImage(UIImage(name: "plus", pointSize: 19, weight: .medium)?.withRenderingMode(.alwaysTemplate), for: .normal)
        contentEdgeInsets.left = 17
        imageEdgeInsets.bottom = 2
        titleEdgeInsets.left = 16
        tintColor = Colors.orange
        self.adjustsImageWhenHighlighted = false
    
        self.setTitle("New folder", for: .normal)
        setTitleColor(Colors.orange, for: .normal)
        titleLabel?.font = Fonts.medium.withSize(17)
        
        contentHorizontalAlignment = .left
        
        self.highlightAction = {
            [weak self] highlighted in
            guard let self = self else { return }
            if highlighted {
                self.alpha = 0.25
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.alpha = 1
                }
            }
        }
    }
    
    override func tintColorDidChange() {
        if self.tintAdjustmentMode == .dimmed {
            self.setTitleColor(Colors.lightText, for: .normal)
        }
        else {
            self.setTitleColor(Colors.orange, for: .normal)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
}

fileprivate class JournalTabHeader: UIView {
    
    private let label = UILabel()
    
    init() {
        super.init(frame: .zero)
        
        label.text = "Journal"
        label.font = Fonts.medium.withSize(17)
        label.textColor = Colors.lightText
        self.addSubview(label)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.sizeToFit()
        label.frame.origin = CGPoint(
            x: 16,
            y: self.bounds.maxY - label.bounds.height)
        
    }
}

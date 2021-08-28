//
//  MergeProfilesViewController.swift
//  Andante
//
//  Created by Miles Vinson on 3/13/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit
import Combine
import CoreData

class MergeProfilesViewController: UIViewController, UITableViewDelegate {
    
    public var profile: CDProfile
    
    private let header = ModalViewHeader(title: "Merge Profiles")
    
    private let profileImgView = ProfileImageView()
    private let profileLabel = UILabel()
    private let currentSessionsLabel = UILabel()
    private let newSessionsLabel = UILabel()
    private let arrowIcon = UIImageView()
    
    private let topSep = Separator(position: .top)
    private let botSep = Separator(position: .bottom)
    private let textView = UITextView()
    
    private var cancellables = Set<AnyCancellable>()
    
    private let tableView = UITableView()
    private var fetchController: FetchedObjectTableViewController<CDProfile>!
    
    private var selectedProfiles = Set<CDProfile>()
    private let mergeButton = BottomActionButton(title: "Merge Profiles")
    
    init(_ profile: CDProfile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Colors.foregroundColor
        
        tableView.rowHeight = 70
        tableView.separatorColor = .clear
        tableView.register(MergeProfileCell.self, forCellReuseIdentifier: "cell")
        tableView.allowsMultipleSelection = true
        tableView.backgroundColor = .clear
        tableView.delegate = self
        
        let request = CDProfile.fetchRequest() as NSFetchRequest<CDProfile>
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(CDProfile.creationDate), ascending: true)]
        request.predicate = NSPredicate(format: "uuid != %@", profile.uuid ?? "")
        
        fetchController = FetchedObjectTableViewController(
            tableView: tableView,
            fetchRequest: request,
            managedObjectContext: DataManager.context)
        
        fetchController.cellProvider = { (tableView, indexPath, profile) in
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "cell", for: indexPath) as! MergeProfileCell
            cell.profile = profile
            return cell
        }
        
        fetchController.performFetch()
        
        profile.objectWillChange.sink {
            [weak self] in
            guard let self = self else { return }
            if self.profile.isDeleted {
                self.dismiss(animated: true, completion: nil)
            }
        }.store(in: &cancellables)
        
        view.addSubview(tableView)
        
        header.showsCancelButton = true
        header.cancelButtonAction = {
            [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
        }
        header.showsSeparator = false
        view.addSubview(header)
        
        profileImgView.profile = profile
        view.addSubview(profileImgView)
        
        profile.publisher(for: \.name).sink {
            [weak self] name in
            guard let self = self else { return }
            self.profileLabel.text = name
            self.setTextViewText()
        }.store(in: &cancellables)
        profileLabel.textColor = Colors.text
        profileLabel.font = Fonts.bold.withSize(20)
        profileLabel.textAlignment = .center
        view.addSubview(profileLabel)
        
        let sessionCount = profile.sessions?.count ?? 0
        currentSessionsLabel.attributedText = sessionsText(sessionCount)
        newSessionsLabel.attributedText = sessionsText(sessionCount)
        
        arrowIcon.image = UIImage(name: "arrow.right", pointSize: 15, weight: .semibold)
        arrowIcon.setImageColor(color: Colors.text)
        
        view.addSubviews([currentSessionsLabel, newSessionsLabel, arrowIcon])
        
        topSep.inset = .zero
        botSep.inset = .zero
        textView.backgroundColor = Colors.text.withAlphaComponent(0.02)
        textView.textColor = Colors.text.withAlphaComponent(0.6)
        textView.isUserInteractionEnabled = false
        textView.textContainerInset = UIEdgeInsets(
            t: 14, l: Constants.margin - 5, b: 14, r: Constants.margin - 5)
                
        view.addSubviews([textView, topSep, botSep])
        
        setMergeButton()
        mergeButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.merge()
        }
        view.addSubview(mergeButton)
        
    }
    
    private func merge() {
        
        //needs to be background context
        let alert = CenterLoadingViewController(style: .indefinite)
        self.present(alert, animated: false, completion: nil)
        
        let context = DataManager.backgroundContext
        let request = CDProfile.fetchRequest() as NSFetchRequest<CDProfile>
        request.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let profileID = self.profile.objectID
        let mergeProfileIDs = self.selectedProfiles.map { $0.objectID }
        
        User.shared.isForcingSync = true
        
        DispatchQueue.global(qos: .background).async {
            Thread.sleep(forTimeInterval: 1)
            
            guard let profile = try? context.existingObject(with: profileID) as? CDProfile else { return }
            
            for mergeProfileID in mergeProfileIDs {
                
                if let mergeProfile = try? context.existingObject(with: mergeProfileID) as? CDProfile {
                    
                    if let sessions = mergeProfile.sessions as? Set<CDSession> {
                        for session in sessions {
                            profile.addToSessions(session.duplicate(context: context))
                        }
                    }
                    
                    if let folders = mergeProfile.journalFolders as? Set<CDJournalFolder> {
                        
                        let sortedFolders = folders.sorted { (f1, f2) -> Bool in
                            return f1.index < f2.index
                        }
                        
                        for folder in sortedFolders {
                            if folder.isDefaultFolder == false {
                                let folder = folder.duplicate(context: context)
                                folder.index = Int64(profile.journalFolders?.count ?? 0)
                                profile.addJournalFolder(folder)
                            }
                            else {
                                if let defaultFolder = profile.getDefaultFolder(),
                                   let entries = folder.duplicate(context: context).entries as? Set<CDJournalEntry> {
                                    
                                    var defaultEntries = defaultFolder.getEntries()
                                    defaultEntries.append(contentsOf: entries.sorted(by: { (e1, e2) -> Bool in
                                        return e1.index < e2.index
                                    }))
                                    
                                    for entry in entries {
                                        defaultFolder.addToEntries(entry)
                                    }
                                    
                                    defaultFolder.updateEntryOrder(toMatch: defaultEntries)
            
                                }
                            }
                        }
                    }
                    
                    for reminder in CDReminder.getAllReminders(context: context) {
                        if reminder.profileID == mergeProfile.uuid {
                            reminder.profileID = profile.uuid
                        }
                    }
                    
                    context.delete(mergeProfile)
                    
                }
                
            }
            
            try? context.save()
            
            DispatchQueue.main.async {
                CDReminder.rescheduleAllNotifications()
                WidgetDataManager.writeData()
                
                alert.closeAction = {
                    [weak self] in
                    guard let self = self else { return }
                    self.dismiss(animated: true, completion: nil)
                }
                alert.close(success: true)
            }
            
        }
        
    }
    
    private func setMergeButton() {
        if selectedProfiles.count == 0 {
            mergeButton.isUserInteractionEnabled = false
            mergeButton.button.layer.shadowColor = UIColor.clear.cgColor
            mergeButton.button.backgroundColor = Colors.lightColor
            mergeButton.button.setTitleColor(Colors.extraLightText, for: .normal)
        } else {
            mergeButton.isUserInteractionEnabled = true
            mergeButton.button.layer.shadowColor = UIColor.black.cgColor
            mergeButton.button.backgroundColor = Colors.orange
            mergeButton.button.setTitleColor(Colors.white, for: .normal)
        }
    }
    
    private func setTextViewText() {
        let str = NSMutableAttributedString(string: "Choose profiles to merge into ", attributes: [
            .font : Fonts.regular.withSize(15)
        ])
        str.append(NSAttributedString(string: "\(profile.name ?? "Profile"). ", attributes: [
            .font : Fonts.semibold.withSize(15)
        ]))
        str.append(NSAttributedString(string: "The profiles you select will be deleted after moving their Sessions and Journal Entries into ", attributes: [
            .font : Fonts.regular.withSize(15)
        ]))
        str.append(NSAttributedString(string: "\(profile.name ?? "").", attributes: [
            .font : Fonts.semibold.withSize(15)
        ]))
        textView.attributedText = str
    }
    
    private func sessionsText(_ sessions: Int) -> NSAttributedString {
        let str = NSMutableAttributedString(string: "\(sessions)", attributes: [
            .font : Fonts.medium.withSize(16),
            .foregroundColor : Colors.text
        ])
        let sessions = sessions == 1 ? "session" : "sessions"
        str.append(NSAttributedString(string: " \(sessions)", attributes: [
            .font : Fonts.regular.withSize(16),
            .foregroundColor : Colors.lightText
        ]))
        return str
    }
    
    private func updateSessionsText() {
        var sessions = profile.sessions?.count ?? 0
        selectedProfiles.forEach { sessions += $0.sessions?.count ?? 0 }
        newSessionsLabel.attributedText = sessionsText(sessions)
        layoutSessionLabels()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let headerHeight = header.sizeThatFits(self.view.bounds.size).height
        header.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: headerHeight)
        
        profileImgView.bounds.size = CGSize(90)
        profileImgView.inset = 14
        profileImgView.center = CGPoint(
            x: view.bounds.midX,
            y: header.frame.maxY + 10 + profileImgView.bounds.height/2)
        
        profileLabel.frame = CGRect(
            x: Constants.margin, y: profileImgView.frame.maxY + 16,
            width: view.bounds.width - Constants.margin*2, height: 24)
        
        layoutSessionLabels()
        
        let height = textView.sizeThatFits(self.view.bounds.size).height
        textView.frame = CGRect(
            x: 0, y: currentSessionsLabel.frame.maxY + 16,
            width: view.bounds.width,
            height: height)
        topSep.frame = textView.frame
        botSep.frame = textView.frame
        
        tableView.frame = CGRect(
            x: 0, y: botSep.frame.maxY,
            width: view.bounds.width,
            height: view.bounds.maxY - botSep.frame.maxY)
        
        let buttonHeight = mergeButton.sizeThatFits(self.view.bounds.size).height
        mergeButton.frame = CGRect(
            x: 0, y: view.bounds.maxY - buttonHeight,
            width: view.bounds.width,
            height: buttonHeight)
        
    }
    
    private func layoutSessionLabels() {
        currentSessionsLabel.sizeToFit()
        newSessionsLabel.sizeToFit()
        Layout.HStack(
            [currentSessionsLabel, arrowIcon, newSessionsLabel],
            centerY: profileLabel.frame.maxY + 20,
            spacing: 12,
            position: .center
        )
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if
            let id = fetchController.dataSource.itemIdentifier(for: indexPath),
            let profile = try? DataManager.context.existingObject(with: id) as? CDProfile
        {
            selectedProfiles.insert(profile)
            updateSessionsText()
            setMergeButton()
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if
            let id = fetchController.dataSource.itemIdentifier(for: indexPath),
            let profile = try? DataManager.context.existingObject(with: id) as? CDProfile
        {
            selectedProfiles.remove(profile)
            updateSessionsText()
            setMergeButton()
        }
    }
    
}

fileprivate class MergeProfileCell: UITableViewCell {
    
    private let imgView = ProfileImageView()
    private let labelGroup = LabelGroup()
    
    private let checkBG = UIView()
    private var checkView = UIImageView()
    
    private var cancellables = Set<AnyCancellable>()
    
    public var profile: CDProfile? {
        didSet {
            guard let profile = profile else { return }
            
            imgView.profile = profile
            
            profile.publisher(for: \.name).sink {
                [weak self] name in
                guard let self = self else { return }
                self.labelGroup.titleLabel.text = name
            }.store(in: &cancellables)
            
            profile.publisher(for: \.sessions).sink {
                [weak self] sessions in
                guard let self = self else { return }
                let count = sessions?.count ?? 0
                let sessions = count == 1 ? "session" : "sessions"
                self.labelGroup.detailLabel.text = "\(count) \(sessions)"
            }.store(in: &cancellables)
            
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = Colors.foregroundColor
        selectionStyle = .none
        
        addSubview(imgView)
        
        labelGroup.titleLabel.textColor = Colors.text
        labelGroup.titleLabel.font = Fonts.semibold.withSize(16)
        labelGroup.detailLabel.textColor = Colors.lightText
        labelGroup.detailLabel.font = Fonts.regular.withSize(15)
        labelGroup.padding = 1
       
        addSubview(labelGroup)
        
        checkBG.backgroundColor = Colors.lightColor
        addSubview(checkBG)
        
        checkView.image = UIImage(name: "checkmark", pointSize: 11, weight: .bold)
        checkView.setImageColor(color: Colors.white)
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            checkBG.backgroundColor = Colors.orange
            addSubview(checkView)
        } else {
            checkBG.backgroundColor = Colors.lightColor
            checkView.removeFromSuperview()
        }
        
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if highlighted {
            self.backgroundColor = Colors.cellHighlightColor
        } else {
            UIView.animate(withDuration: 0.25) {
                self.backgroundColor = Colors.foregroundColor
            }
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imgView.frame = CGRect(
            x: Constants.smallMargin,
            y: self.bounds.midY - 22,
            width: 44, height: 44)

        let checkSize: CGFloat = 24
        checkBG.frame = CGRect(
            center: CGPoint(x: bounds.maxX - Constants.smallMargin - checkSize/2, y: bounds.midY),
            size: CGSize(checkSize))
        checkView.sizeToFit()
        checkView.center = checkBG.center
        
        checkBG.roundCorners()
        
        labelGroup.frame = CGRect(
            from: CGPoint(x: imgView.frame.maxX + 12, y: 0),
            to: CGPoint(x: checkBG.frame.minX - 14, y: self.bounds.maxY))
        
    }
}


//
//  ExportDataViewController.swift
//  Andante
//
//  Created by Miles Vinson on 9/12/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit
import CoreData

class ExportDataViewController: SettingsDetailViewController {
    
    private let button = BottomActionButton(title: "Export Data")
    
    private let titleLabel = UILabel()
    private let descriptionView = UITextView()
    
    private let profileCellView = DetailLabelCellView()
    
    private let titleCellView = ToggleCellView(
        title: "Include Titles",
        icon: "tag.fill",
        iconColor: Colors.sessionsColor
    )
    
    private let notesCellView = ToggleCellView(
        title: "Include Notes",
        icon: "doc.plaintext.fill",
        iconColor: Colors.lightBlue
    )
        
    private let activityIndicator = UIActivityIndicatorView()
    
    private var isExporting = false
    private var didCancelExport = false
    
    private var showProfileCell = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = nil
        
        self.backgroundColor = Colors.foregroundColor
        self.scrollView.alwaysBounceVertical = false
        self.scrollView.delaysContentTouches = false
        
        button.margin = 24
        button.color = .clear
        button.action = {
            [weak self] in
            guard let self = self else { return }
            self.didTapButton()
        }
        activityIndicator.color = Colors.white
        button.button.addSubview(activityIndicator)
        self.scrollView.addSubview(button)
        
        titleLabel.textColor = Colors.text
        titleLabel.font = Fonts.bold.withSize(27)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.text = "Export Practice Data"
        self.scrollView.addSubview(titleLabel)
        
        descriptionView.textColor = Colors.lightText
        descriptionView.font = Fonts.regular.withSize(18)
        descriptionView.text = "Export your practice sessions as a .csv file so you can manipulate, analyze, and visualize your data however you want."
        descriptionView.textContainerInset.left = Constants.margin
        descriptionView.textContainerInset.right = Constants.margin
        descriptionView.textAlignment = .center
        descriptionView.isEditable = false
        descriptionView.isScrollEnabled = false
        descriptionView.backgroundColor = .clear
        self.scrollView.addSubview(descriptionView)
                
        if CDProfile.getAllProfiles().count > 1 {
            self.showProfileCell = true
            
            let profile = User.getActiveProfile() ?? CDProfile.getAllProfiles().first
            profileCellView.profile = profile
            profileCellView.detailText = profile?.name
            profileCellView.alternateProfileTitle = "Profile"
            
            profileCellView.action = { [weak self] in
                guard let self = self, self.isExporting == false else { return }
                
                let vc = ProfilesPopupViewController()
                vc.allowsAllProfiles = false
                vc.selectedProfile = self.profileCellView.profile
                vc.useNewProfileButton = false
                vc.action = {
                    [weak self] profile in
                    guard let self = self else { return }
                    self.profileCellView.profile = profile
                    self.profileCellView.detailText = profile?.name
                }
                
                self.presentPopupViewController(vc)
                
            }
            self.scrollView.addSubview(self.profileCellView)
        }
        
        titleCellView.isOn = Settings.includeTitleInExport
        titleCellView.toggleAction = { isOn in
            Settings.includeTitleInExport = isOn
        }
        self.scrollView.addSubview(self.titleCellView)
        
        notesCellView.isOn = Settings.includeNotesInExport
        notesCellView.toggleAction = { isOn in
            Settings.includeNotesInExport = isOn
        }
        self.scrollView.addSubview(self.notesCellView)
        
        [profileCellView, titleCellView, notesCellView].forEach {
            $0.margin = CGFloat(28)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        titleLabel.sizeToFit()
        let titleHeight = titleLabel.sizeThatFits(CGSize(width: view.bounds.width - Constants.margin*2, height: .infinity)).height
        titleLabel.center = CGPoint(
            x: self.scrollView.bounds.midX, y: 40)
        titleLabel.bounds.size = CGSize(width: view.bounds.width - Constants.margin * 2, height: titleHeight)
        
        let height = descriptionView.sizeThatFits(CGSize(width: view.bounds.width, height: .infinity)).height
        descriptionView.frame = CGRect(
            x: 0, y: titleLabel.frame.maxY + 8,
            width: scrollView.bounds.width,
            height: height)
        
        button.sizeToFit()
        button.bounds.size.width = view.bounds.width
        let minY = self.scrollView.bounds.maxY - button.bounds.height
        button.frame.origin = CGPoint(
            x: 0, y: minY)
        
        let itemHeight = AndanteCellView.height
        let cellMinY = descriptionView.frame.maxY + 32
        
        var cells: [UIView] = [titleCellView, notesCellView]
        
        if showProfileCell {
            cells.insert(profileCellView, at: 0)
        }
        
        for (i, cell) in cells.enumerated() {
            cell.frame = CGRect(
                x: 0,
                y: cellMinY + (CGFloat(i) * itemHeight),
                width: view.bounds.width,
                height: itemHeight
            )
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        didCancelExport = true
    }
    
    func didTapButton() {
        guard
            let profile = profileCellView.profile ?? User.getActiveProfile(),
            isExporting == false
        else { return }
        
        didCancelExport = false

        activityIndicator.sizeToFit()
        activityIndicator.center = CGPoint(x: 30, y: button.button.bounds.midY)
        activityIndicator.startAnimating()
        
        let context = DataManager.backgroundContext
        context.performAndWait {
            let fetchRequest = CDSession.fetchRequest() as NSFetchRequest<CDSession>
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(CDSession.d_startTime), ascending: false)]
            fetchRequest.predicate = NSPredicate(format: "profile == %@", profile)
            
            do {
                let sessions = try context.fetch(fetchRequest)
                self.createFile(profile: profile, sessions: sessions) {
                    [weak self] url in
                    guard let self = self else { return }

                    DispatchQueue.main.async {
                        if self.didCancelExport { return }

                        let ac = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                        ac.popoverPresentationController?.sourceView = self.button
                        self.presentModal(ac, animated: true, completion: {
                            [weak self] in
                            guard let self = self else { return }
                            self.isExporting = false
                            self.activityIndicator.stopAnimating()
                        })
                        
                        ac.completionWithItemsHandler = { (type, completed, items, error) in
                            try? FileManager.default.removeItem(at: url)
                        }
                    }
                }
            } catch {
                print("Export data: Couldn't fetch data")
            }
            
        }
        
    }
    
    func createFile(profile: CDProfile, sessions: [CDSession], completion: ((_:URL)->Void)?) {
        let filename = "\(profile.name ?? "Profile") Practice Log.csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let includeTitle = Settings.includeTitleInExport
        let includeNotes = Settings.includeNotesInExport
        
        var text = ""
        
        if includeTitle {
            text += "Title,"
        }
        
        text += "Duration,Start Date,End Date,Mood,Focus"
        
        if includeNotes {
            text += ",Notes"
        }
                        
        for session in sessions {
            
            let duration = session.practiceTime
            let start = dateFormatter.string(from: session.startTime)
            let end = dateFormatter.string(from: session.getEndTime())
            
            if includeTitle {
                text += "\n\(session.title ?? "Practice")"
            }
            else {
                text += "\n"
            }
            
            text += "\(duration),\(start),\(end),\(session.mood),\(session.focus)"
            
            if includeNotes {
                text += ",\"\(session.notes ?? "")\""
            }
            
        }
        
        do {
            try text.write(to: url, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print(error.localizedDescription)
        }
        
        completion?(url)
        
    }
    
    
}

fileprivate class ExportView: UIView {
    
    public let titleLabel = UILabel()
    public let indicator = UIActivityIndicatorView()
    
    init() {
        super.init(frame: .zero)
        
        titleLabel.textColor = Colors.text
        titleLabel.font = Fonts.bold.withSize(33)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.text = "Generating File"
        self.addSubview(titleLabel)

        self.addSubview(indicator)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        titleLabel.sizeToFit()
        titleLabel.center = CGPoint(
            x: self.bounds.midX, y: 90)
        
        indicator.sizeToFit()
        indicator.center = self.bounds.center
            
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class OptionsView: UIView {
    
    private let titleLabel = UILabel()
    private let descriptionView = UITextView()
    public let profileView = SelectProfileView()
    
    init() {
        super.init(frame: .zero)
        
        titleLabel.textColor = Colors.text
        titleLabel.font = Fonts.bold.withSize(33)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.text = "Export Practice\nLog"
        self.addSubview(titleLabel)
        
        descriptionView.textColor = Colors.lightText
        descriptionView.font = Fonts.regular.withSize(19)
        descriptionView.text = "Export your practice sessions as a .csv file so you can manipulate, analyze, and visualize your data however you want."
        descriptionView.textContainerInset.left = Constants.margin
        descriptionView.textContainerInset.right = Constants.margin
        descriptionView.textAlignment = .center
        descriptionView.isEditable = false
        descriptionView.isScrollEnabled = false
        descriptionView.backgroundColor = .clear
        self.addSubview(descriptionView)
        
        self.addSubview(profileView)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        titleLabel.sizeToFit()
        titleLabel.center = CGPoint(
            x: self.bounds.midX, y: 90)
        
        let height = descriptionView.sizeThatFits(self.bounds.size).height
        descriptionView.frame = CGRect(
            x: 0, y: titleLabel.frame.maxY + 8,
            width: self.bounds.width,
            height: height)
        
        profileView.frame = CGRect(
            x: 10, y: descriptionView.frame.maxY + 24,
            width: self.bounds.width - 20,
            height: 70)
        
    }
}

fileprivate class SelectProfileView: CustomButton {
    
    private let imgView = ProfileImageView()
    private let label = UILabel()
    private let arrow = UIImageView()
    
    public var profile: CDProfile! {
        didSet {
            imgView.profile = profile
            label.text = profile.name
        }
    }
    
    public var toggleHandler: ((_:Bool)->Void)?
    
    override init() {
        super.init()
        
        profile = User.getActiveProfile()!
        
        imgView.profile = profile
        self.addSubview(imgView)
        
        label.text = profile.name
        label.textColor = Colors.text
        label.font = Fonts.medium.withSize(17)
        self.addSubview(label)
        
        arrow.image = UIImage(name: "chevron.down", pointSize: 16, weight: .medium)
        arrow.setImageColor(color: Colors.lightText)
        self.addSubview(arrow)
                
        self.highlightAction = {
            [weak self] isHighlighted in
            guard let self = self else { return }
            
            if isHighlighted {
                UIView.animate(withDuration: 0.15) {
                    self.backgroundColor = Colors.cellHighlightColor
                }
            }
            else {
                UIView.animate(withDuration: 0.3) {
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
        
        imgView.frame = CGRect(x: Constants.smallMargin, y: self.bounds.midY - 22,
                                   width: 44, height: 44)
        
        arrow.sizeToFit()
        arrow.frame.origin = CGPoint(
            x: self.bounds.maxX - Constants.smallMargin - arrow.bounds.width,
            y: self.bounds.midY - arrow.bounds.height/2)
        
        label.frame = CGRect(
            from: CGPoint(x: imgView.frame.maxX + 12, y: 0),
            to: CGPoint(x: arrow.frame.maxX - Constants.smallMargin, y: self.bounds.maxY))
        
    }
}

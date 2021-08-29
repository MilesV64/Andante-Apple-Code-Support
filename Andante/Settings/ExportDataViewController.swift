//
//  ExportDataViewController.swift
//  Andante
//
//  Created by Miles Vinson on 9/12/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit
import CoreData

class ExportDataViewController: UIViewController {
    
    private let header = ModalViewHeader()
    private let button = BottomActionButton(title: "Export Data")
    
    private let titleLabel = UILabel()
    private let descriptionView = UITextView()
    
    private let optionsView = MaskedShadowView()
    private let profileView = ProfileOptionPickerView()
    private let notesToggleLabel = UILabel()
    private let separator = Separator()
    private let notesToggle = UISwitch()
    
    private let activityIndicator = UIActivityIndicatorView()
    
    private var isExporting = false
    private var didCancelExport = false
    
    private var phase = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = Colors.backgroundColor
        
        self.view.addSubview(header)
        header.showsSeparator = false
        header.showsHandle = false
        header.showsCancelButton = true
        header.cancelButtonAction = {
            [weak self] in
            guard let self = self else { return }
            self.didCancelExport = true
            self.dismiss(animated: true, completion: nil)
        }
        header.backgroundColor = .clear
        
        button.color = .clear
        button.style = .floating
        button.action = {
            [weak self] in
            guard let self = self else { return }
            self.didTapButton()
        }
        activityIndicator.color = Colors.white
        button.button.addSubview(activityIndicator)
        self.view.addSubview(button)
        
        titleLabel.textColor = Colors.text
        titleLabel.font = Fonts.bold.withSize(33)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.text = "Export Practice\nData"
        self.view.addSubview(titleLabel)
        
        descriptionView.textColor = Colors.lightText
        descriptionView.font = Fonts.regular.withSize(19)
        descriptionView.text = "Export your practice sessions as a .csv file so you can manipulate, analyze, and visualize your data however you want."
        descriptionView.textContainerInset.left = Constants.margin
        descriptionView.textContainerInset.right = Constants.margin
        descriptionView.textAlignment = .center
        descriptionView.isEditable = false
        descriptionView.isScrollEnabled = false
        descriptionView.backgroundColor = .clear
        self.view.addSubview(descriptionView)
                
        profileView.profile = User.getActiveProfile()
        profileView.bgView.backgroundColor = .clear
        profileView.margin = 0
        profileView.selectHandler = {
            [weak self] in
            guard let self = self, self.isExporting == false else { return }
            
            let vc = ProfilesPopupViewController()
            vc.selectedProfile = self.profileView.profile
            vc.useNewProfileButton = false
            vc.action = {
                [weak self] profile in
                guard let self = self else { return }
                self.profileView.profile = profile
            }
            
            self.presentPopupViewController(vc)
            
        }
        
        separator.inset = UIEdgeInsets(l: Constants.margin)
        separator.position = .top
        
        notesToggleLabel.text = "Include Notes"
        notesToggleLabel.textColor = Colors.text
        notesToggleLabel.font = Fonts.medium.withSize(16)
        
        notesToggle.onTintColor = Colors.green
        notesToggle.isOn = Settings.includeNotesInExport
        notesToggle.addTarget(self, action: #selector(didToggleInludeNotes), for: .touchUpInside)

        optionsView.addSubview(profileView)
        optionsView.addSubview(separator)
        optionsView.addSubview(notesToggleLabel)
        optionsView.addSubview(notesToggle)
        self.view.addSubview(optionsView)
    }
    
    @objc func didToggleInludeNotes() {
        Settings.includeNotesInExport = notesToggle.isOn
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        header.sizeToFit()
        header.bounds.size.width = self.view.bounds.width
        header.frame.origin = .zero
        
        titleLabel.sizeToFit()
        let titleHeight = titleLabel.sizeThatFits(CGSize(width: view.bounds.width - Constants.margin*2, height: .infinity)).height
        titleLabel.center = CGPoint(
            x: self.view.bounds.midX, y: header.frame.maxY + 60)
        titleLabel.bounds.size = CGSize(width: view.bounds.width - Constants.margin * 2, height: titleHeight)
        
        let height = descriptionView.sizeThatFits(CGSize(width: view.bounds.width, height: .infinity)).height
        descriptionView.frame = CGRect(
            x: 0, y: titleLabel.frame.maxY + 8,
            width: view.bounds.width,
            height: height)
        
        let itemHeight: CGFloat = 54
        optionsView.frame = CGRect(
            x:  Constants.smallMargin,
            y: descriptionView.frame.maxY + 28,
            width: view.bounds.width - Constants.smallMargin*2, height: itemHeight*2)
        
        profileView.frame = CGRect(
            x: 0, y: 0, width: optionsView.bounds.width, height: itemHeight)
        
        separator.frame = CGRect(
            x: 0, y: profileView.frame.maxY,
            width: optionsView.bounds.width, height: 1)
        
        notesToggleLabel.sizeToFit()
        notesToggleLabel.frame.origin = CGPoint(
            x: Constants.margin, y: itemHeight + itemHeight/2 - notesToggleLabel.bounds.height/2)
        
        notesToggle.sizeToFit()
        notesToggle.frame.origin = CGPoint(
            x: optionsView.bounds.width - Constants.smallMargin - notesToggle.bounds.width,
            y: notesToggleLabel.center.y - notesToggle.bounds.height/2)
        
        button.sizeToFit()
        button.bounds.size.width = view.bounds.width
        let minY = self.view.bounds.maxY - button.bounds.height
        button.frame.origin = CGPoint(
            x: 0, y: minY)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        didCancelExport = true
    }
    
    func didTapButton() {
        guard
            let profile = profileView.profile,
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
                        self.present(ac, animated: true, completion: {
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
        
        var text = "Duration,Start Date,End Date,Mood,Focus"
        
        if notesToggle.isOn {
            text += ",Notes"
        }
                        
        for session in sessions {
            
            let duration = session.practiceTime
            let start = dateFormatter.string(from: session.startTime)
            let end = dateFormatter.string(from: session.getEndTime())
            
            text += "\n\(duration),\(start),\(end),\(session.mood),\(session.focus)"
            
            if notesToggle.isOn {
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

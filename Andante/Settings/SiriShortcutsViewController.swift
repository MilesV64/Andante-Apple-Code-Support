//
//  SiriShortcutsViewController.swift
//  Andante
//
//  Created by Miles Vinson on 9/20/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit
import CoreData
import Combine
import IntentsUI

class SiriShortcutsViewController: SettingsDetailViewController, UITableViewDelegate {
    
    private let tableView = UITableView()
    private var fetchController: FetchedObjectTableViewController<CDProfile>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.backgroundColor = Colors.backgroundColor
        
        self.title = "Siri Shortcuts"
        
        tableView.separatorColor = .clear
        tableView.backgroundColor = Colors.backgroundColor
        tableView.register(SiriShortcutCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.rowHeight = 84
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 10))
        self.view.addSubview(tableView)
        
        let request = CDProfile.fetchRequest() as NSFetchRequest<CDProfile>
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(CDProfile.creationDate), ascending: true)]
        
        fetchController = FetchedObjectTableViewController(tableView: tableView, fetchRequest: request, managedObjectContext: DataManager.context)
        
        fetchController.cellProvider = { (tableView, indexPath, profile) in
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SiriShortcutCell
            cell.profile = profile
            return cell
        }
        
        fetchController.performFetch()
                
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let profile = fetchController.object(at: indexPath) {
            let shortcut = INShortcut(userActivity: profile.getSiriActivity())
            
            let vc = INUIAddVoiceShortcutViewController(shortcut: shortcut)
            vc.view.tintColor = Colors.orange
            vc.delegate = self
            self.presentModal(vc, animated: true, completion: nil)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = CGRect(
            from: CGPoint(x: 0, y: headerView.frame.maxY),
            to: CGPoint(x: view.bounds.maxX, y: view.bounds.maxY))
    }
    
}

extension SiriShortcutsViewController: INUIAddVoiceShortcutViewControllerDelegate {
    
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
}

class SiriShortcutCell: UITableViewCell {
    
    private let bgView = MaskedShadowView()
    private let icon = ProfileImageView()
    private let titleLabel = UILabel()
    private let arrow = UIImageView()
        
    private var cancellables = Set<AnyCancellable>()
    
    public var profile: CDProfile? {
        didSet {
            cancellables.removeAll()
            if let profile = profile {
                icon.profile = profile
                profile.publisher(for: \.name).sink {
                    [weak self] name in
                    guard let self = self else { return }
                    self.titleLabel.text = "Start practicing \((name ?? "Profile").lowercased())"
                }.store(in: &cancellables)
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        self.backgroundColor = .clear
        
        icon.isUserInteractionEnabled = false
        bgView.addSubview(icon)
        
        titleLabel.font = Fonts.medium.withSize(16)
        titleLabel.textColor = Colors.text
        titleLabel.isUserInteractionEnabled = false
        bgView.addSubview(titleLabel)
        
        arrow.image = UIImage(name: "chevron.right", pointSize: 13, weight: .semibold)
        arrow.tintColor = Colors.extraLightText
        arrow.isUserInteractionEnabled = false
        bgView.addSubview(arrow)
        
        self.addSubview(bgView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            bgView.pushDown()
        } else {
            bgView.pushUp()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bgView.frame = self.bounds.insetBy(dx: Constants.smallMargin, dy: 4)
        
        icon.bounds.size = CGSize(44)
        icon.frame.origin = CGPoint(x: Constants.smallMargin, y: bgView.bounds.midY - icon.bounds.height/2)
        
        arrow.sizeToFit()
        arrow.frame.origin = CGPoint(
            x: bgView.bounds.maxX - Constants.margin - 2 - arrow.bounds.width,
            y: bgView.bounds.midY - arrow.bounds.height/2)
        
        titleLabel.frame = CGRect(
            from: CGPoint(x: icon.frame.maxX + 14, y: 0),
            to: CGPoint(x: arrow.frame.minX - 12, y: bgView.bounds.maxY))
        
    }
}


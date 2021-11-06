//
//  ProfilesPopupViewController.swift
//  Andante
//
//  Created by Miles Vinson on 2/27/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit
import CoreData
import Combine

class ProfilesPopupViewController: PopupViewController, UITableViewDelegate, FetchedObjectControllerDelegate {
        
    private var newProfileButton: BottomActionButton?
    
    private let tableView = UITableView()
    private var fetchController: FetchedObjectTableViewController<CDProfile>?
    
    private var allProfilesCellView = CheckmarkCellView(title: "All Profiles", icon: "person.2.fill", iconColor: Colors.orange)
    
    public var selectedProfile: CDProfile?
    
    public var allowsAllProfiles = true
    public var useNewProfileButton = true
    public var newProfileAction: (()->())?
    public var action: ((CDProfile?)->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let request = CDProfile.fetchRequest() as NSFetchRequest<CDProfile>
        request.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        fetchController = FetchedObjectTableViewController(
            tableView: tableView,
            fetchRequest: request,
            managedObjectContext: DataManager.context)
        
        fetchController?.cellProvider = {
            [weak self] (tableView, indexPath, profile) in
            guard let self = self else { return UITableViewCell() }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CheckmarkTableViewCell
            
            cell.checkmarkCellView.margin = 24
            cell.checkmarkCellView.profile = profile
            cell.checkmarkCellView.setChecked(profile == self.selectedProfile, animated: false)
            
            return cell
            
        }
        
        fetchController?.performFetch()
        
        tableView.delaysContentTouches = false
        tableView.alwaysBounceVertical = false
        tableView.rowHeight = CheckmarkCellView.height
        tableView.register(CheckmarkTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .clear
        tableView.separatorColor = .clear
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 4))
        contentView.addSubview(tableView)
        
        if self.allowsAllProfiles {
            self.allProfilesCellView.setChecked(self.selectedProfile == nil, animated: false)
            self.allProfilesCellView.margin = 24
            self.allProfilesCellView.action = { [weak self] in
                self?.selectProfile(nil)
            }
            tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: AndanteCellView.height))
            tableView.tableHeaderView?.addSubview(self.allProfilesCellView)
        } else {
            tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        }
        
        if useNewProfileButton {
            newProfileButton = BottomActionButton(title: "New Profile")
            newProfileButton?.color = .clear
            newProfileButton?.action = {
                [weak self] in
                guard let self = self else { return }
                self.closeCompletion = self.newProfileAction
                self.close()
            }
            contentView.addSubview(newProfileButton!)
        }
        else {
            newProfileButton = BottomActionButton(title: "Cancel")
            newProfileButton?.color = .clear
            newProfileButton?.button.backgroundColor = Colors.lightColor
            newProfileButton?.button.setTitleColor(Colors.text, for: .normal)
            newProfileButton?.action = {
                [weak self] in
                guard let self = self else { return }
                self.close()
            }
            contentView.addSubview(newProfileButton!)
        }
        
        newProfileButton?.margin = 20
        
        newProfileButton?.backgroundColor = .clear
        
        panGesture.delegate = self
        tableView.delegate = self
        tableView.contentInsetAdjustmentBehavior = .never
        
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if panGesture.velocity(in: nil).y > 0 {
            if (scrollView.contentOffset.y + scrollView.contentInset.top) <= 0 {
                scrollView.isScrollEnabled = false
                scrollView.isScrollEnabled = true
            }
            else {
                disablePanWithoutClosing()
            }
        
        }
        else {
            panGesture.isEnabled = false
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        panGesture.isEnabled = true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func fetchedObjectControllerDidUpdate(isEmpty: Bool, firstUpdate: Bool) {
        if !firstUpdate {
            viewDidLayoutSubviews()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let profile = fetchController?.controller.object(at: indexPath) {
            self.selectProfile(profile)
        }
    }
    
    private func selectProfile(_ profile: CDProfile?) {
        self.view.isUserInteractionEnabled = false
        
        for indexPath in tableView.indexPathsForVisibleRows ?? [] {
            if let cell = tableView.cellForRow(at: indexPath) as? CheckmarkTableViewCell {
                cell.checkmarkCellView.setChecked(cell.checkmarkCellView.profile == profile, animated: true)
            }
        }
        self.allProfilesCellView.setChecked(profile == nil, animated: true)
        
        action?(profile)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.close()
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        var tableHeight: CGFloat = tableView.rowHeight * CGFloat(fetchController?.numberOfItems() ?? 0) + 10
    
        tableHeight += tableView.tableHeaderView?.bounds.height ?? 0
        
        let buttonHeight = newProfileButton == nil ? 0 : BottomActionButton.height
        
        preferredContentHeight = min(self.view.bounds.height*0.8, tableHeight + buttonHeight)

        super.viewDidLayoutSubviews()
        
        tableView.frame = CGRect(
            x: 0, y: 10,
            width: contentView.bounds.width,
            height: tableHeight)
        
        allProfilesCellView.frame = CGRect(
            x: 0, y: 0, width: tableView.bounds.width, height: AndanteCellView.height)
        
        newProfileButton?.frame = CGRect(
            x: 0, y: contentView.bounds.maxY - buttonHeight,
            width: contentView.bounds.width, height: buttonHeight)
        
    }
    
}


class SelectProfileCell: UITableViewCell {
    
    private let profileView = ProfileImageView()
    private let label = UILabel()
    
    private var cancellables = Set<AnyCancellable>()
        
    public var profile: CDProfile? = nil {
        didSet {
            cancellables.removeAll()
            
            guard let profile = profile else { return }
            
            profile.publisher(for: \.name).sink {
                [weak self] name in
                guard let self = self else { return }
                self.label.text = name
            }.store(in: &cancellables)
            
            profileView.profile = profile
            
        }
    }
    
    private var checkView: UIImageView?
    
    public var useCheckmark = false {
        didSet {
            if useCheckmark {
                label.textColor = Colors.orange
                checkView = UIImageView()
                checkView?.image = UIImage(name: "checkmark.circle.fill", pointSize: 20, weight: .semibold)
                checkView?.tintColor = Colors.orange.withAlphaComponent(0.9)
                self.addSubview(checkView!)
                setNeedsLayout()
            }
            else {
                label.textColor = Colors.text
                checkView?.removeFromSuperview()
                checkView = nil
                setNeedsLayout()
            }
        }
    }
    
    private let button = UIButton(type: .system)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        self.backgroundColor = .clear
        
        profileView.backgroundColor = Colors.lightColor
        self.addSubview(profileView)
        
        label.textColor = Colors.text
        label.font = Fonts.medium.withSize(16)

        self.addSubview(label)
        
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            self.backgroundColor = Colors.cellHighlightColor
        }
        else {
            UIView.animate(withDuration: 0.2) {
                self.backgroundColor = .clear
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        profileView.frame = CGRect(x: Constants.smallMargin, y: self.bounds.midY - 24,
                                   width: 48, height: 48)
        
        if let checkView = checkView {
            checkView.sizeToFit()
            checkView.frame.origin = CGPoint(
                x: self.bounds.maxX - Constants.margin - checkView.bounds.width,
                y: self.bounds.midY - checkView.bounds.height/2)
        }
        
        label.frame = CGRect(
            from: CGPoint(x: profileView.frame.maxX + 12, y: 0),
            to: CGPoint(x: (checkView?.frame.minX ?? self.bounds.maxX) - Constants.smallMargin, y: self.bounds.maxY))
        
        
    }
}

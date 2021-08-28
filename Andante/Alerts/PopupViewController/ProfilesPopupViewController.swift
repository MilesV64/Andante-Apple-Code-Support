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
    
    private let headerView = Separator()
    private let headerLabel = UILabel()
    
    private var newProfileButton: BottomActionButton?
    
    private let tableView = UITableView()
    private var fetchController: FetchedObjectTableViewController<CDProfile>?
    
    private let selectFeedback = UIImpactFeedbackGenerator(style: .light)
    
    public var selectedProfile: CDProfile?
    
    public var useNewProfileButton = true
    public var newProfileAction: (()->())?
    public var action: ((CDProfile)->())?
    
    override var title: String? {
        didSet {
            headerLabel.text = title
        }
    }
    
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
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SelectProfileCell
            cell.profile = profile
            cell.useCheckmark = profile == self.selectedProfile
            
            return cell
            
        }
        
        fetchController?.performFetch()
        
        headerLabel.font = Fonts.semibold.withSize(17)
        headerLabel.textColor = Colors.text
        headerLabel.textAlignment = .center
        headerLabel.text = title
        headerView.addSubview(headerLabel)
        
        headerView.position = .bottom
        //contentView.addSubview(headerView)
        
        tableView.alwaysBounceVertical = false
        tableView.rowHeight = 70
        tableView.register(SelectProfileCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .clear
        tableView.separatorColor = .clear
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 1))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 4))
        contentView.addSubview(tableView)
        
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
            newProfileButton?.button.layer.shadowOpacity = 0
            newProfileButton?.action = {
                [weak self] in
                guard let self = self else { return }
                self.close()
            }
            contentView.addSubview(newProfileButton!)
        }
        
        newProfileButton?.backgroundColor = .clear
        
        panGesture.delegate = self
        tableView.delegate = self
        tableView.contentInsetAdjustmentBehavior = .never
        
        selectFeedback.prepare()
        
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
            selectFeedback.impactOccurred()
            action?(profile)
            self.close()
        }
    }
    
    override func viewDidLayoutSubviews() {
        let tableHeight: CGFloat = tableView.rowHeight * CGFloat(fetchController?.numberOfItems() ?? 0) + 5
        
        let buttonHeight = newProfileButton == nil ? 0 : BottomActionButton.height
        
        preferredContentHeight = tableHeight + buttonHeight

        super.viewDidLayoutSubviews()
        
        tableView.frame = CGRect(
            x: 0, y: 0,
            width: contentView.bounds.width,
            height: tableHeight)
        
        newProfileButton?.frame = CGRect(
            x: 0, y: contentView.bounds.maxY - buttonHeight - contentView.safeAreaInsets.bottom,
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

//
//  MoveSessionViewController.swift
//  Andante
//
//  Created by Miles Vinson on 9/9/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class MoveSessionViewController: UIViewController {
    
    private let header = ModalViewHeader(title: "Move Session")
    private let tableView = UITableView()
    
    private var data: [CDProfile] = []
    public var session: CDSession!
    
    private let sessionView = PracticeSessionView()
    private let sessionSep = Separator(position: .bottom)
    private let spacer = Separator(position: .bottom)
    
    public var moveHandler: ((_: CDProfile)->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.preferredContentSize = CGSize(width: 360, height: 440)
                        
        data = CDProfile.getAllProfiles()
        
        tableView.separatorInset = .zero
        tableView.separatorColor = Colors.separatorColor
        tableView.backgroundColor = Colors.backgroundColor
        tableView.tableFooterView = UIView()
        
        sessionView.setSession(session)
        sessionView.backgroundColor = Colors.foregroundColor
        sessionView.addSubview(sessionSep)
        
        spacer.backgroundColor = Colors.backgroundColor
        
        tableView.tableHeaderView = UIView()
        tableView.tableHeaderView?.addSubview(sessionView)
        tableView.tableHeaderView?.addSubview(spacer)
        
        tableView.register(ProfileCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = 70
        
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        self.view.backgroundColor = Colors.backgroundColor
        header.showsCancelButton = true
        header.cancelButtonAction = {
            [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
        }
        header.showsHandle = traitCollection.horizontalSizeClass == .compact
        self.view.addSubview(header)
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        header.showsHandle = traitCollection.horizontalSizeClass == .compact
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        header.sizeToFit()
        header.bounds.size.width = self.view.bounds.width
        header.frame.origin = .zero
        
        tableView.frame = CGRect(
            from: CGPoint(x: 0, y: header.frame.maxY),
            to: CGPoint(x: self.view.bounds.maxX, y: self.view.bounds.maxY))
        
        tableView.tableHeaderView?.bounds.size.height = 96
        sessionView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 84)
        sessionSep.frame = sessionView.bounds
        spacer.frame = CGRect(x: 0, y: sessionView.frame.maxY, width: self.view.bounds.width, height: 12)
        
        
    }
    
}

extension MoveSessionViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ProfileCell
        
        cell.profile = data[indexPath.row]
        cell.isEnabled = cell.profile != session.profile
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        moveHandler?(data[indexPath.row])
    }
    
}

fileprivate class ProfileCell: UITableViewCell {
        
    private let profileView = ProfileImageView()
    private let label = UILabel()
        
    public var profile: CDProfile? = nil {
        didSet {
            guard let profile = profile else { return }
            
            profileView.profile = profile
            label.text = profile.name
        }
    }
    
    public var isEnabled: Bool = true {
        didSet {
            if isEnabled {
                let alpha: CGFloat = 1
                self.profileView.alpha = alpha
                self.label.alpha = alpha
                self.isUserInteractionEnabled = true
            }
            else {
                let alpha: CGFloat = 0.25
                self.profileView.alpha = alpha
                self.label.alpha = alpha
                self.isUserInteractionEnabled = false
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        self.backgroundColor = Colors.foregroundColor
        self.contentView.backgroundColor = Colors.foregroundColor
        
        profileView.backgroundColor = Colors.lightColor
        contentView.addSubview(profileView)
        
        label.textColor = Colors.text
        label.font = Fonts.medium.withSize(16)

        contentView.addSubview(label)
        
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            contentView.backgroundColor = Colors.cellHighlightColor
        }
        else {
            UIView.animate(withDuration: 0.2) {
                self.contentView.backgroundColor = Colors.foregroundColor
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        profileView.frame = CGRect(x: Constants.smallMargin, y: self.bounds.midY - 23,
                                   width: 46, height: 46)
        
        label.frame = CGRect(
            from: CGPoint(x: profileView.frame.maxX + 12, y: 0),
            to: CGPoint(x: self.bounds.maxX - Constants.smallMargin, y: self.bounds.maxY))
        
        
    }
}

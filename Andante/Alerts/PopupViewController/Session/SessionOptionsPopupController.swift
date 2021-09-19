//
//  SessionOptionsPopupController.swift
//  Andante
//
//  Created by Miles Vinson on 2/23/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit
import Combine

class SessionOptionsPopupController: TransitionPopupViewController {
    
    enum ShareType {
        case session, notes, recording
        var string: String {
            switch self {
            case .session: return "Share session"
            case .notes: return "Share notes"
            case .recording: return "Share recording"
            }
        }
    }
    
    public var session: CDSession?
    
    private let optionsView = PopupOptionsView()
    
    private let profileOptionView = AndanteCellView()
    private let editSessionView = AndanteCellView(title: "Edit Session", icon: "switch.2", iconColor: Colors.orange)
    
    public var deleteHandler: (()->())?
    public var editHandler: (()->())?
    public var moveHandler: ((CDProfile)->())?
    
    public var shareHandler: ((Set<ShareType>)->())?
    
    private var cancellables = Set<AnyCancellable>()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let session = self.session else { return }
        
        optionsView.addOption(title: "Share", iconName: "square.and.arrow.up", destructive: false) {
            [weak self] in
            guard let self = self else { return }
            self.handleShare()
        }
        
        let isFavorited = session.isFavorited
        optionsView.addOption(
            title: isFavorited ? "Unfavorite" : "Favorite",
            iconName: isFavorited ? "heart.fill" : "heart",
            destructive: false, action: {
                session.isFavorited = !session.isFavorited
                DataManager.saveContext()
            })
        
        session.publisher(for: \.isFavorited).sink {
            [weak self] isFavorited in
            guard let self = self else { return }
            if isFavorited {
                self.optionsView.option(at: 1)?.label.text = "Unfavorite"
                self.optionsView.option(at: 1)?.iconView.image = UIImage(name: "heart.fill", pointSize: 18, weight: .medium)
            }
            else {
                self.optionsView.option(at: 1)?.label.text = "Favorite"
                self.optionsView.option(at: 1)?.iconView.image = UIImage(name: "heart", pointSize: 18, weight: .medium)
            }
        }.store(in: &cancellables)
        
        
        optionsView.addOption(title: "Delete", iconName: "trash", destructive: true) {
            [weak self] in
            guard let self = self else { return }
            self.handleDelete()
        }
        
        primaryView.addSubview(optionsView)
        
        profileOptionView.margin = 24
        profileOptionView.profile = session.profile
        profileOptionView.alternateProfileTitle = "Move Session"
        profileOptionView.action = {
            [weak self] in
            guard let self = self else { return }
            let moveView = MoveSessionPopupView(session: session)
            moveView.moveAction = {
                [weak self] profile in
                guard let self = self else { return }
                self.popSecondaryView()
                self.close()
                self.moveHandler?(profile)
            }
            self.push(moveView)
        }
        primaryView.addSubview(profileOptionView)
        
        editSessionView.margin = 24
        editSessionView.action = {
            [weak self] in
            guard let self = self else { return }
            self.closeCompletion = self.editHandler
            self.close()
        }
        primaryView.addSubview(editSessionView)
    }
    
    private func handleDelete() {
        let areYouSure = PopupAreYouSureView(
            self,
            isDistructive: true,
            title: "Are you sure?",
            description: "This cannot be undone.",
            destructiveText: "Delete Session",
            cancelText: "Cancel",
            destructiveAction: {
                [weak self] in
                guard let self = self else { return }
                self.closeCompletion = {
                    [weak self] in
                    guard let self = self else { return }
                    self.deleteHandler?()
                }
                self.close()
            })
        
        areYouSure.cancelAction = {
            [weak self] in
            guard let self = self else { return }
            self.popSecondaryView()
        }
    
        self.push(areYouSure)
    }
    
    private func handleShare() {
        guard let session = self.session else { return }
        
        if session.hasNotes == false && session.hasRecording == false {
            self.closeCompletion = {
                [weak self] in
                guard let self = self else { return }
                self.shareHandler?([.session])
            }
            self.close()
        }
        else {
            let shareView = SessionSharePopupView(session: session)
            shareView.action = {
                [weak self] selectedOptions in
                guard let self = self else { return }
                
                self.closeCompletion = {
                    [weak self] in
                    guard let self = self else { return }
                    self.shareHandler?(selectedOptions)
                }
                
                self.close()
                
            }
            
            self.push(shareView)
        }
        
        
    }
    
    
    override func preferredHeightForPrimaryView(for width: CGFloat) -> CGFloat {
        let optionsHeight = PopupOptionsView.height
        let otherOptionHeight: CGFloat = 60
        return optionsHeight + otherOptionHeight*2 + 20
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let optionsHeight = PopupOptionsView.height
        let otherOptionHeight: CGFloat = AndanteCellView.height
        
        optionsView.frame = CGRect(
            x: 24,
            y: 0,
            width: contentView.bounds.width - 24*2,
            height: optionsHeight)
        
        profileOptionView.frame = CGRect(
            x: 0, y: optionsView.frame.maxY + 8,
            width: contentView.bounds.width,
            height: otherOptionHeight)
        
        editSessionView.frame = CGRect(
            x: 0, y: profileOptionView.frame.maxY,
            width: contentView.bounds.width,
            height: otherOptionHeight)
        
    }
    
}

fileprivate class SessionProfileButton: CustomButton {
    
    private let iconView = ProfileImageView()
    private let label = UILabel()
    
    public var profile: CDProfile? {
        didSet {
            iconView.profile = profile
        }
    }
    
    override init() {
        super.init()
        
        addSubview(iconView)
        iconView.cornerRadius = Constants.iconBGCornerRadius
        
        label.text = "Move session"
        label.font = Fonts.medium.withSize(16)
        
        if CDProfile.getAllProfiles().count > 1 {
            label.textColor = Colors.text
            self.isUserInteractionEnabled = true
        } else {
            label.textColor = Colors.extraLightText
            self.isUserInteractionEnabled = false
        }
        
        addSubview(label)
        
        highlightAction = {
            [weak self] highlighted in
            guard let self = self else { return }
            if highlighted {
                self.backgroundColor = Colors.cellHighlightColor
            } else {
                UIView.animate(withDuration: 0.25) {
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
        
        iconView.bounds.size = Constants.iconBGSize
        iconView.center = CGPoint(x: Constants.smallMargin + iconView.bounds.width/2, y: bounds.midY)
        
        label.frame = CGRect(
            from: CGPoint(x: iconView.frame.maxX + 16, y: 0),
            to: CGPoint(x: bounds.maxX - Constants.smallMargin, y: bounds.maxY))
        
    }
}

fileprivate class EditSessionButton: CustomButton {
    
    private let iconView = IconView()
    private let label = UILabel()
    
    override init() {
        super.init()
        
        iconView.icon = UIImage(name: "switch.2", pointSize: 18, weight: .regular)
        
        iconView.iconColor = Colors.white
        iconView.backgroundColor = Colors.orange
        iconView.roundCorners(Constants.iconBGCornerRadius)
        addSubview(iconView)
        
        label.text = "Edit session"
        label.textColor = Colors.text
        label.font = Fonts.medium.withSize(16)
        addSubview(label)
        
        highlightAction = {
            [weak self] highlighted in
            guard let self = self else { return }
            if highlighted {
                self.backgroundColor = Colors.cellHighlightColor
            } else {
                UIView.animate(withDuration: 0.25) {
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
        
        iconView.iconSize = iconView.icon?.size
        iconView.bounds.size = Constants.iconBGSize
        iconView.center = CGPoint(x: Constants.smallMargin + iconView.bounds.width/2, y: bounds.midY)
        
        label.frame = CGRect(
            from: CGPoint(x: iconView.frame.maxX + 16, y: 0),
            to: CGPoint(x: bounds.maxX - Constants.smallMargin, y: bounds.maxY))
        
    }
}

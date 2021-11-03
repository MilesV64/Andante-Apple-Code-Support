//
//  SessionOptionsPopupStackView.swift
//  Andante
//
//  Created by Miles on 10/29/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit
import Combine

class SessionOptionsPopupStackView: PopupStackContentView {
    
    override func preferredHeight(for width: CGFloat) -> CGFloat {
        let optionsHeight = PopupOptionsView.height
        let otherOptionHeight: CGFloat = 60
        return optionsHeight + otherOptionHeight*2 + 20 + 24
    }
    
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
    
    let session: CDSession
    
    private let optionsView = PopupOptionsView()
    
    private let profileOptionView = AndanteCellView()
    private let editSessionView = AndanteCellView(title: "Edit Session", icon: "switch.2", iconColor: Colors.orange)
    
    public var deleteHandler: (()->())?
    public var editHandler: (()->())?
    public var moveHandler: ((CDProfile)->())?
    
    public var shareHandler: ((Set<ShareType>)->())?
    
    private var cancellables = Set<AnyCancellable>()
    
    
    init(session: CDSession) {
        self.session = session
        
        super.init(frame: .zero)
        
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
        
        addSubview(optionsView)
        
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
                self.popupViewController?.hide(completion: {
                    self.moveHandler?(profile)
                })
            }
            //self.push(moveView)
        }
        addSubview(profileOptionView)
        
        editSessionView.margin = 24
        editSessionView.action = {
            [weak self] in
            guard let self = self else { return }
            self.popupViewController?.hide(completion: {
                self.editHandler?()
            })
        }
        addSubview(editSessionView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func handleDelete() {
        let alert = ActionTrayPopupStackContentView(
            title: "Are you sure?",
            description: "This will permanently delete the session across all devices."
        )
        
        alert.addAction("Delete Session", isDestructive: true) {
            self.popupViewController?.hide(completion: {
                self.deleteHandler?()
            })
        }
        
        self.popupViewController?.push(alert)
    }
    
    private func handleShare() {
        if session.hasNotes == false && session.hasRecording == false {
            self.popupViewController?.hide(completion: { [weak self] in
                self?.shareHandler?([.session])
            })
        }
        else {
//            let shareView = SessionSharePopupView(session: session)
//            shareView.action = {
//                [weak self] selectedOptions in
//                guard let self = self else { return }
//
//                self.popupViewController?.hide(completion: {
//                    self.shareHandler?(selectedOptions)
//                })
//
//            }
            
            //self.push(shareView)
        }
        
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let optionsHeight = PopupOptionsView.height
        let otherOptionHeight: CGFloat = AndanteCellView.height
        
        optionsView.frame = CGRect(
            x: 24,
            y: 20,
            width: self.bounds.width - 24*2,
            height: optionsHeight)
        
        profileOptionView.frame = CGRect(
            x: 0, y: optionsView.frame.maxY + 8,
            width: self.bounds.width,
            height: otherOptionHeight)
        
        editSessionView.frame = CGRect(
            x: 0, y: profileOptionView.frame.maxY,
            width: self.bounds.width,
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

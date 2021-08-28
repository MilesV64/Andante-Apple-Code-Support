//
//  JournalEntryOptionsViewController.swift
//  Andante
//
//  Created by Miles Vinson on 2/18/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class JournalEntryOptionsViewController: TransitionPopupViewController {
    
    private let optionsView = PopupOptionsView()
    
    public var entry: CDJournalEntry?
    
    private let folderInfo = InfoView(title: "Folder")
    private let editedInfo = InfoView(title: "Last Modified")
    private let createdInfo = InfoView(title: "Created")
    
    public var shareHandler: (()->())?
    public var moveHandler: ((CDJournalFolder)->())?
    public var newFolderHandler: (()->())?
    public var deleteHandler: (()->())?
    public var askForDeletePredicate: (()->Bool)?
    
    init(entry: CDJournalEntry?) {
        super.init()
        self.entry = entry
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        optionsView.addOption(
            title: "Share",
            iconName: "square.and.arrow.up",
            destructive: false, action: {
                [weak self] in
                guard let self = self else { return }
                self.closeCompletion = self.shareHandler
                self.close()
            })
        
        optionsView.addOption(
            title: "Move",
            iconName: "folder",
            destructive: false, action: {
                [weak self] in
                guard let self = self else { return }
                self.didSelectMove()
            })
        
        optionsView.addOption(
            title: "Delete",
            iconName: "trash",
            destructive: true
        ) {
            
            [weak self] in
            guard let self = self else { return }
            
            if self.askForDeletePredicate?() ?? true {
                let areYouSure = PopupAreYouSureView(
                    self,
                    isDistructive: true,
                    title: "Are you sure?",
                    description: "This cannot be undone.",
                    destructiveText: "Delete Entry",
                    cancelText: "Cancel",
                    destructiveAction: {
                        [weak self] in
                        guard let self = self else { return }
                        self.deleteHandler?()
                        self.close()
                    })
                
                areYouSure.cancelAction = {
                    [weak self] in
                    guard let self = self else { return }
                    self.popSecondaryView()
                }
            
                self.push(areYouSure)
            }
            else {
                self.closeCompletion = self.deleteHandler
                self.close()
            }
            
        }
        
        primaryView.addSubview(optionsView)
        
        
        folderInfo.dataText = entry?.folder?.title
        editedInfo.dataText = formatDate(entry?.editDate ?? Date())
        createdInfo.dataText = formatDate(entry?.creationDate ?? Date())
        
        primaryView.addSubviews([folderInfo, editedInfo, createdInfo])
        
    }
    
    func didSelectMove() {
        guard let entry = entry else { return }
        let moveView = MoveEntryPopupView(entry: entry)
        moveView.moveAction = {
            [weak self] folder in
            guard let self = self else { return }
            
            self.close()
            self.moveHandler?(folder)
    
        }
        self.push(moveView)
    }
    
    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        
        if date.isTheSameDay(as: Date()) {
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .short
        }
        else {
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none
        }
        
        return dateFormatter.string(from: date)
    }
    
    override func preferredHeightForPrimaryView(for width: CGFloat) -> CGFloat {
        let optionsHeight = PopupOptionsView.height
        let infoItemHeight: CGFloat = 56
        return optionsHeight + infoItemHeight*3 + 8 + 16
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let optionsHeight = PopupOptionsView.height
        let infoItemHeight: CGFloat = 56
        
        optionsView.frame = CGRect(
            x: Constants.smallMargin,
            y: 0,
            width: contentView.bounds.width - Constants.smallMargin*2,
            height: optionsHeight)
        
        for (i, item) in [folderInfo, editedInfo, createdInfo].enumerated() {
            item.frame = CGRect(
                x: 0, y: optionsView.frame.maxY + 8 + CGFloat(i)*infoItemHeight,
                width: contentView.bounds.width,
                height: infoItemHeight)
            item.color = .clear
        }
        
    }
    
}


fileprivate class InfoView: Separator {
    
    private let titleLabel = UILabel()
    private let dataLabel = UILabel()
    
    public var dataText: String? {
        didSet {
            dataLabel.text = dataText
        }
    }
    
    init(title: String) {
        super.init(frame: .zero)
        
        self.position = .top
        self.color = .clear
        
        titleLabel.text = title
        titleLabel.textColor = Colors.text
        titleLabel.font = Fonts.regular.withSize(16)
        self.addSubview(titleLabel)
        
        dataLabel.text = title
        dataLabel.textColor = Colors.text
        dataLabel.font = Fonts.medium.withSize(16)
        dataLabel.textAlignment = .right
        self.addSubview(dataLabel)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        titleLabel.sizeToFit()
        titleLabel.frame.origin = CGPoint(
            x: Constants.margin,
            y: self.bounds.midY - titleLabel.bounds.height/2)
        
        dataLabel.frame = CGRect(
            from: CGPoint(x: titleLabel.frame.maxX + Constants.margin, y: 0),
            to: CGPoint(x: self.bounds.maxX - Constants.margin, y: self.bounds.maxY))
        
    }
}

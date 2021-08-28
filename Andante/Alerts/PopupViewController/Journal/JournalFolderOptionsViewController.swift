//
//  JournalFolderOptionsViewController.swift
//  Andante
//
//  Created by Miles Vinson on 2/18/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class JournalFolderOptionsViewController: TransitionPopupViewController {
    
    private let optionsView = PopupOptionsView()
    
    public var optionsEnabled = true {
        didSet {
            optionsView.isEnabled = optionsEnabled
        }
    }
    
    public var selectedLayoutOption: JournalViewController.EntryLayout = .list {
        didSet {
            listOptionView.setSelected(selectedLayoutOption == .list)
            gridOptionView.setSelected(selectedLayoutOption == .grid)
        }
    }
    
    private var listOptionView = LayoutOptionView(.list)
    private var gridOptionView = LayoutOptionView(.grid)
        
    public var renameHandler: (()->())?
    public var deleteHandler: (()->())?
    public var askForDeletePredicate: (()->Bool)?
    public var layoutHandler: ((_:JournalViewController.EntryLayout)->())?
    
    public var folder: CDJournalFolder?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        optionsView.addOption(
            title: "Rename",
            iconName: "pencil",
            destructive: false, action: {
                [weak self] in
                guard let self = self else { return }
                
                self.closeCompletion = self.renameHandler
                self.close()
                
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
                    destructiveText: "Delete Folder",
                    cancelText: "Cancel",
                    destructiveAction: {
                        [weak self] in
                        guard let self = self else { return }
                        self.close()
                        self.deleteHandler?()
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
        
        listOptionView.setSelected(selectedLayoutOption == .list)
        listOptionView.action = {
            [weak self] in
            guard let self = self else { return }
            self.listOptionView.setSelected(true)
            self.gridOptionView.setSelected(false)
            self.layoutHandler?(.list)
        }
        primaryView.addSubview(listOptionView)
        
        gridOptionView.setSelected(selectedLayoutOption == .grid)
        gridOptionView.action = {
            [weak self] in
            guard let self = self else { return }
            self.listOptionView.setSelected(false)
            self.gridOptionView.setSelected(true)
            self.layoutHandler?(.grid)
        }
        primaryView.addSubview(gridOptionView)
        
    }
    
    override func preferredHeightForPrimaryView(for width: CGFloat) -> CGFloat {
        let optionsHeight = PopupOptionsView.height
        let layoutOptHeight: CGFloat = 52
        return optionsHeight + layoutOptHeight*2 + 46
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let optionsHeight = PopupOptionsView.height
        let layoutOptHeight: CGFloat = 52
        
        optionsView.frame = CGRect(
            x: Constants.smallMargin,
            y: 0,
            width: contentView.bounds.width - Constants.smallMargin*2,
            height: optionsHeight)
        
        listOptionView.frame = CGRect(
            x: Constants.smallMargin, y: optionsView.frame.maxY + 20,
            width: contentView.bounds.width - Constants.smallMargin*2,
            height: layoutOptHeight)
        
        gridOptionView.frame = CGRect(
            x: Constants.smallMargin, y: listOptionView.frame.maxY + 8,
            width: contentView.bounds.width - Constants.smallMargin*2,
            height: layoutOptHeight)
        
    }
    
}


fileprivate class LayoutOptionView: CustomButton {
    
    private let iconView = UIImageView()
    private let label = UILabel()
    private var isSelectedOption = false
        
    init(_ layout: JournalViewController.EntryLayout) {
        super.init()
        
        if layout == .list {
            iconView.image = UIImage(name: "rectangle.grid.1x2.fill", pointSize: 20, weight: .medium)
            label.text = "List"
        } else {
            iconView.image = UIImage(name: "rectangle.grid.2x2.fill", pointSize: 20, weight: .medium)
            label.text = "Grid"
        }
        
        
        addSubview(iconView)
        addSubview(label)
        
        roundCorners(12)
        
        highlightAction = {
            [weak self] highlighted in
            guard let self = self else { return }
            
            if highlighted && !self.isSelectedOption {
                self.backgroundColor = Colors.lightColor
            } else if !self.isSelectedOption {
                UIView.animate(withDuration: 0.3) {
                    self.backgroundColor = .clear
                }
            }
            
        }
        
    }
    
    public func setSelected(_ selected: Bool) {
        self.isSelectedOption = selected
        
        if selected {
            iconView.tintColor = Colors.white
            label.textColor = Colors.white
            backgroundColor = Colors.orange
            label.font = Fonts.semibold.withSize(16)
            isUserInteractionEnabled = false
        } else {
            iconView.tintColor = Colors.text.withAlphaComponent(0.9)
            label.textColor = Colors.text.withAlphaComponent(0.9)
            backgroundColor = .clear
            label.font = Fonts.medium.withSize(16)
            isUserInteractionEnabled = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        iconView.sizeToFit()
        iconView.center = CGPoint(x: 28, y: bounds.midY)
        
        label.frame = CGRect(
            from: CGPoint(x: 52, y: 0),
            to: CGPoint(x: bounds.maxX - 8, y: bounds.maxY))
        
    }
}

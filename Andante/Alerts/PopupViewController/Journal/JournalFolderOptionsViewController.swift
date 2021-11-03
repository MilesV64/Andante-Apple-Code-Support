//
//  JournalFolderOptionsViewController.swift
//  Andante
//
//  Created by Miles Vinson on 2/18/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class JournalFolderOptionsViewController: TransitionPopupViewController, SegmentedPickerViewDelegate {
    
    private let optionsView = PopupOptionsView()
    
    public var optionsEnabled = true {
        didSet {
            optionsView.isEnabled = optionsEnabled
        }
    }
    
    public var selectedLayoutOption: JournalViewController.EntryLayout = .list {
        didSet {
            if self.selectedLayoutOption == .list {
                self.layoutPicker.selectOption(at: 0, animated: false)
            } else {
                self.layoutPicker.selectOption(at: 1, animated: false)
            }
        }
    }
    
    private let layoutPicker: SegmentedPickerView = {
        let picker = SegmentedPickerView()
        picker.insertOption(LayoutOptionView(.list), at: 0)
        picker.insertOption(LayoutOptionView(.grid), at: 1)
        return picker
    }()
    
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
        
        layoutPicker.delegate = self
        
        primaryView.addSubview(layoutPicker)
        
    }
    
    func segmentedPickerView(_ view: SegmentedPickerView, didSelectOptionAt index: Int) {
        self.layoutHandler?(index == 0 ? .list : .grid)
    }
    
    override func preferredHeightForPrimaryView(for width: CGFloat) -> CGFloat {
        let optionsHeight = PopupOptionsView.height
        let layoutOptHeight: CGFloat = 50
        return optionsHeight + layoutOptHeight + 52
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let optionsHeight = PopupOptionsView.height
        
        optionsView.frame = CGRect(
            x: 24,
            y: 0,
            width: contentView.bounds.width - 48,
            height: optionsHeight)
        
        layoutPicker.frame = CGRect(
            x: 22, y: optionsView.frame.maxY + 20,
            width: contentView.bounds.width - 44, height: 56
        )
        
    }
    
}


fileprivate class LayoutOptionView: UIView, SegmentedPickerOptionView {
    
    private let iconView = UIImageView()
    private let label = UILabel()
        
    init(_ layout: JournalViewController.EntryLayout) {
        super.init(frame: .zero)
        
        if layout == .list {
            iconView.image = UIImage(name: "rectangle.grid.1x2.fill", pointSize: 19, weight: .medium)
            label.text = "List"
        } else {
            iconView.image = UIImage(name: "rectangle.grid.2x2.fill", pointSize: 19, weight: .medium)
            label.text = "Grid"
        }
        
        label.font = Fonts.medium.withSize(16)
        addSubview(iconView)
        addSubview(label)
        
    }
    
    
    
    func setSelected(_ selected: Bool) {
        if selected {
            iconView.tintColor = Colors.white
            label.textColor = Colors.white
        } else {
            iconView.tintColor = Colors.lightText
            label.textColor = Colors.lightText
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.sizeToFit()
        iconView.sizeToFit()
        
        let totalWidth = label.bounds.width + iconView.bounds.width + 8
        
        iconView.center = CGPoint(x: bounds.midX - 4 - totalWidth/2 + iconView.bounds.width/2, y: bounds.midY)
        
        label.center = CGPoint(x: iconView.contextualFrame.maxX + 8 + label.bounds.width/2, y: bounds.midY)
        
    }
}

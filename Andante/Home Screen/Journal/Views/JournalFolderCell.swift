//
//  JournalFolderCell.swift
//  Andante
//
//  Created by Miles Vinson on 7/17/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit
import Combine

class JournalFolderCell: UITableViewCell {
    
    private let bgView = MaskedShadowView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    
    public var isActive = false {
        didSet {
            if isActive {
                iconView.tintColor = Colors.orange
                titleLabel.textColor = Colors.orange
            } else {
                iconView.tintColor = Colors.lightText
                titleLabel.textColor = Colors.text
            }
            
        }
    }
    
    public var folder: CDJournalFolder? {
        didSet {
            
            cancellables.removeAll()
            
            folder?.objectWillChange.sink {
                [weak self] in
                guard let self = self else { return }
                
                self.titleLabel.text = self.folder?.title
                let entries = self.folder?.entries?.count ?? 0
                self.detailLabel.text = "\(entries) \(entries == 1 ? "entry" : "entries")"
                
            }.store(in: &cancellables)
            
            titleLabel.text = folder?.title
            let entries = folder?.entries?.count ?? 0
            detailLabel.text = "\(entries) \(entries == 1 ? "entry" : "entries")"
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        self.backgroundColor = .clear
        
        contentView.addSubview(bgView)
        
        iconView.image = UIImage(name: "folder.fill", pointSize: 16, weight: .medium)
        iconView.tintColor = Colors.lightText
        bgView.addSubview(iconView)
        
        titleLabel.textColor = Colors.text
        titleLabel.font = Fonts.medium.withSize(16)
        bgView.addSubview(titleLabel)
        
        detailLabel.text = "test"
        detailLabel.textColor = Colors.lightText
        detailLabel.font = Fonts.regular.withSize(15)
        bgView.addSubview(detailLabel)
        
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            bgView.pushDown()
        } else {
            bgView.pushUp()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bgView.frame = self.bounds.insetBy(dx: Constants.smallMargin, dy: 4)
        
        iconView.sizeToFit()
        iconView.center = CGPoint(
            x: Constants.margin + iconView.bounds.width/2,
            y: bgView.bounds.midY)
        
        detailLabel.sizeToFit()
        detailLabel.center = CGPoint(
            x: bgView.bounds.maxX - Constants.margin - detailLabel.bounds.width/2,
            y: bgView.bounds.midY)
        
        titleLabel.frame = CGRect(
            from: CGPoint(x: iconView.frame.maxX + 10, y: 0),
            to: CGPoint(x: detailLabel.frame.minX - 18, y: bgView.bounds.maxY))
        
    }
    
}


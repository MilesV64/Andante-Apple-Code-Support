//
//  CheckmarkCellView.swift
//  Andante
//
//  Created by Miles on 10/24/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

// MARK: - Checkmark Cell

class CheckmarkCellView: AndanteCellView {
    
    private let checkmarkBG = UIView()
    private var checkmarkImageView: UIImageView?
    
    override var accessoryView: UIView? {
        return self.checkmarkBG
    }
    
    private(set) var isChecked: Bool = false
    
    public func setChecked(_ checked: Bool, animated: Bool = true) {
        guard checked != self.isChecked else { return }
        self.isChecked = checked
        
        if checked {
            let checkmarkImageView = UIImageView(image: UIImage(name: "checkmark", pointSize: 11, weight: .bold)?.withRenderingMode(.alwaysTemplate))
            checkmarkImageView.sizeToFit()
            checkmarkImageView.center = self.checkmarkBG.bounds.center
            checkmarkImageView.tintColor = .white
            self.checkmarkImageView = checkmarkImageView
            self.checkmarkBG.addSubview(checkmarkImageView)
            self.checkmarkBG.backgroundColor = Colors.orange
        }
        else {
            self.checkmarkImageView?.removeFromSuperview()
            self.checkmarkImageView = nil
            self.checkmarkBG.backgroundColor = Colors.lightColor
        }
        
    }
    
    override func sharedInit() {
        super.sharedInit()
        
        self.checkmarkBG.backgroundColor = Colors.lightColor
        self.checkmarkBG.bounds.size = CGSize(24)
        self.checkmarkBG.roundCorners(12, prefersContinuous: false)
        
    }
    
}


// MARK: - Checkmark Cell

class CheckmarkTableViewCell: UITableViewCell {
    
    let checkmarkCellView = CheckmarkCellView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = .clear
        self.addSubview(self.checkmarkCellView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.checkmarkCellView.frame = self.bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


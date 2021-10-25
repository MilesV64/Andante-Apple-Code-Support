//
//  AndanteCellHeaderView.swift
//  Andante
//
//  Created by Miles on 10/24/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit


// MARK: - Andante Cell Header View

class AndanteCellHeaderView: UIView {
    
    static let height: CGFloat = 46 //22 + 8 + 16
    let label = UILabel()
    
    public var margin: CGFloat = Constants.margin
    
    init(title: String) {
        super.init(frame: .zero)
        
        label.text = title.uppercased()
        label.textColor = Colors.lightText
        label.font = Fonts.semibold.withSize(13)
        addSubview(label)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.frame = CGRect(
            x: margin, y: 22,
            width: bounds.width - margin*2,
            height: 16)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

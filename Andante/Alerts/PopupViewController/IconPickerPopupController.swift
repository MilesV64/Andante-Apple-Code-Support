//
//  IconPickerPopupController.swift
//  Andante
//
//  Created by Miles Vinson on 3/5/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class IconPickerPopupController: PopupViewController {
    
    private let picker = IconPickerView()
    public var initialIcon: String? {
        didSet {
            picker.selectedIcon = initialIcon
        }
    }
    public var selectionAction: ((String)->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.contentView.addSubview(picker)
        picker.selectionAction = {
            [weak self] string in
            guard let self = self else { return }
            self.selectionAction?(string)
            self.close()
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        
        let height = picker.sizeThatFits(CGSize(contentWidth - Constants.smallMargin*2)).height
        
        self.preferredContentHeight = height + 28
        
        super.viewDidLayoutSubviews()
        
        picker.frame = CGRect(x: Constants.smallMargin, y: 14, width: contentView.bounds.width - Constants.smallMargin*2, height: height)
        
    }
    
}

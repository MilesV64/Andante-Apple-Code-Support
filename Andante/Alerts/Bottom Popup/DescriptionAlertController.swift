//
//  DescriptionAlertController.swift
//  Andante
//
//  Created by Miles Vinson on 10/15/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class DescriptionAlertController: PickerAlertController {
    
    private let titleLabel = UILabel()
    private let separator = Separator(position: .middle)
    private let textView = UITextView()
    
    public var titleText: String? {
        didSet {
            titleLabel.text = titleText
        }
    }
    
    public var descriptionText: String? {
        didSet {
            textView.text = descriptionText
        }
    }
    
    convenience init(title: String?, description: String?) {
        self.init(nibName: nil, bundle: nil)
        
        titleLabel.text = title
        textView.text = description
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.textColor = Colors.text
        titleLabel.font = Fonts.bold.withSize(17)
        titleLabel.textAlignment = .center
        self.contentView.addSubview(titleLabel)
        
        textView.font = Fonts.regular.withSize(16)
        textView.textColor = Colors.text.withAlphaComponent(0.9)
        textView.textContainerInset.left = Constants.margin + 5
        textView.textContainerInset.right = Constants.margin + 5
        textView.textAlignment = .left
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.backgroundColor = .clear
        self.contentView.addSubview(textView)
        
        self.contentView.addSubview(separator)
        
    }
    
    override func viewDidLayoutSubviews() {
        
        let titleHeight = titleLabel.sizeThatFits(self.view.bounds.size).height
        let textHeight = textView.sizeThatFits(self.view.bounds.size).height
        
        self.contentHeight = titleHeight + textHeight + 8 + 32 + 14
        
        super.viewDidLayoutSubviews()
        
        titleLabel.frame = CGRect(x: 0, y: 8, width: contentView.bounds.width, height: titleHeight)
        
        separator.frame = CGRect(x: 0, y: titleLabel.frame.maxY + 2, width: contentView.bounds.width, height: 24)
        
        textView.frame = CGRect(x: 0, y: separator.frame.maxY - 4, width: self.contentView.bounds.width, height: textHeight)
        
    }
    
}



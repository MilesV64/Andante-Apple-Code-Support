//
//  WhatsNewViewController.swift
//  Andante
//
//  Created by Miles Vinson on 11/18/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class WhatsNewViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    
    private let titleLabel = UILabel()
    private let continueButton = BottomActionButton(title: "Continue")
    
    private var contentCells: [ContentCell] = []

    
    public var closeAction: (()->Void)?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .formSheet
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.preferredContentSize = CGSize(width: 560, height: 800)

        
        view.backgroundColor = Colors.foregroundColor
        
        view.addSubview(scrollView)
        scrollView.showsVerticalScrollIndicator = false
        
        titleLabel.textColor = Colors.text
        titleLabel.font = Fonts.bold.withSize(40)
        titleLabel.text = "What's New"
        titleLabel.textAlignment = .center
        scrollView.addSubview(titleLabel)
        
        continueButton.color = .clear
        continueButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
        }
        view.addSubview(continueButton)
        
        setContent()
    }
    
    private func setContent() {
        
    }
    
    private func addCell(_ cell: ContentCell) {
        scrollView.addSubview(cell)
        contentCells.append(cell)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        closeAction?()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
                
        let width = min(view.bounds.width, 420)
        
        let frame = CGRect(center: view.bounds.center, size: CGSize(width: width - Constants.margin*2, height: view.bounds.height))
        
        titleLabel.frame = CGRect(
            x: frame.minX, y: frame.minY + 60,
            width: frame.width, height: 40)
        
        
        continueButton.frame = CGRect(
            x: frame.minX,
            y: view.bounds.maxY - view.safeAreaInsets.bottom - 100,
            width: frame.width,
            height: 100)
        
        scrollView.frame = CGRect(from: .zero, to: CGPoint(x: view.bounds.maxX, y: continueButton.frame.minY))
        
        
        var minY: CGFloat = titleLabel.frame.maxY + view.bounds.height*0.09
        for cell in contentCells {
            
            let height = cell.sizeThatFits(frame.size).height
            cell.frame = CGRect(
                x: frame.minX, y: minY,
                width: frame.width,
                height: height)
            
            minY += height + 50
            
        }
        
        if let cell = contentCells.last {
            scrollView.contentSize.height = cell.frame.maxY + 24
        }
        
        
    }
    
}

fileprivate class ContentCell: UIView {
    
    private let textView = TitleBodyGroup()
    private let iconView = IconView()
    
    init(iconName: String, iconSize: CGFloat = 22, color: UIColor?, title: String, description: String) {
        super.init(frame: .zero)
        
        iconView.icon = UIImage(name: iconName, pointSize: iconSize, weight: .regular)
        iconView.iconSize = iconView.icon?.size
        iconView.iconColor = Colors.white
        iconView.backgroundColor = color
        iconView.roundCorners(12)
        self.addSubview(iconView)
        
        textView.titleLabel.text = title
        textView.titleLabel.font = Fonts.semibold.withSize(16)
        textView.titleLabel.textColor = Colors.text
        
        textView.textView.text = description
        textView.textView.font = Fonts.regular.withSize(16)
        textView.textView.textColor = Colors.lightText
        
        textView.textView.textContainerInset.left = -5
        textView.textView.textContainerInset.right = -5
        
        textView.margin = 0
        textView.padding = -6
        
        self.addSubview(textView)
        
    }
    
    private var iconSize: CGFloat = 48
    private var spacing: CGFloat = 10
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        
        let textHeight = textView.sizeThatFits(
            CGSize(width: size.width, height: size.height)).height
        
        return CGSize(
            width: size.width,
            height: iconSize + spacing + textHeight)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        iconView.bounds.size = CGSize(iconSize)
        iconView.frame.origin = CGPoint(x: -1, y: 0)
        
        let textHeight = textView.sizeThatFits(
            CGSize(width: bounds.width, height: bounds.height)).height
        
        textView.frame = CGRect(
            x: 0,
            y: iconView.frame.maxY + spacing,
            width: bounds.width,
            height: textHeight)
        
    }
}

//
//  AndanteProViewController.swift
//  Andante
//
//  Created by Miles Vinson on 10/9/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class AndanteProViewController: UIViewController, UIScrollViewDelegate {
    
    private let handleView = HandleView()
    
    private let scrollView = CancelTouchScrollView()
    
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let detailView = UITextView()
    
    private let purchaseButton = PushButton()
    private let restoreButton = UIButton(type: .system)
    
    private let devicesImage = UIImageView()
    
    private let cellBGView = UIView()
    
    private var cells: [FeatureCell] = []
    
    private let iapHelper = IAPHelper.shared
    
    public var successAction: (()->Void)?
    
    private var isPurchasing = false
    private var spinner = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinner.color = Colors.white
                
        iapHelper.successAction = {
            [weak self] in
            guard let self = self else { return }
            self.successAction?()
            self.isPurchasing = false
            self.spinner.stopAnimating()
            self.spinner.removeFromSuperview()
            self.dismiss(animated: true, completion: nil)
        }
        
        iapHelper.failAction = {
            [weak self] in
            guard let self = self else { return }
            self.isPurchasing = false
            self.spinner.stopAnimating()
            self.spinner.removeFromSuperview()
        }
        
        self.view.backgroundColor = Colors.foregroundColor
        
        self.view.addSubview(scrollView)
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        
        titleLabel.textColor = Colors.orange
        titleLabel.font = Fonts.bold.withSize(37)
        titleLabel.text = "Andante Pro"
        titleLabel.textAlignment = .center
        scrollView.addSubview(titleLabel)
        
        detailLabel.text = "One time purchase."
        detailLabel.textColor = Colors.text
        detailLabel.font = Fonts.medium.withSize(17)
        detailLabel.textAlignment = .center
        scrollView.addSubview(detailLabel)
        
        detailView.text = "Get Andante Pro on all your devices, support the app, and get cool features!"
        detailView.textColor = Colors.extraLightText
        detailView.isEditable = false
        detailView.textContainerInset = UIEdgeInsets(l: -5, r: -5)
        detailView.font = Fonts.regular.withSize(17)
        detailView.textAlignment = .center
        detailView.backgroundColor = .clear
        scrollView.addSubview(detailView)
        
        purchaseButton.backgroundColor = Colors.orange
        purchaseButton.buttonView.setButtonShadow()
        purchaseButton.setTitle("Upgrade for \(iapHelper.localizedPrice)", color: Colors.white, font: Fonts.medium.withSize(17))
        purchaseButton.action = {
            [weak self] in
            guard let self = self else { return }
            if self.isPurchasing == false {
                self.iapHelper.requestPurchase()
                self.purchaseButton.addSubview(self.spinner)
                self.spinner.startAnimating()
            }
        }
        scrollView.addSubview(purchaseButton)
        
        restoreButton.setTitle("Restore Purchase", color: Colors.orange, font: Fonts.regular.withSize(15))
        restoreButton.addTarget(self, action: #selector(didTapRestore), for: .touchUpInside)
        scrollView.addSubview(restoreButton)
        
        devicesImage.backgroundColor = Colors.lightColorOpaque.withAlphaComponent(0.75)
        devicesImage.image = UIImage(named: "AndanteProImg")
        devicesImage.roundCorners(12)
        devicesImage.clipsToBounds = true
        scrollView.addSubview(devicesImage)
        
        cellBGView.backgroundColor = Colors.backgroundColor
        scrollView.addSubview(cellBGView)
        
        cells = [
            FeatureCell(
                "Unlimited profiles",
                description: "Use multiple profiles to track every instrument, craft, or skill you're practicing.",
                icon: "person.2.fill", color: UIColor("#2096F3")),
            FeatureCell(
                "Session notes",
                description: "Quickly jot down notes during or after your practice sessions.",
                icon: "speech.bubble.bold", color: Colors.orange),
            FeatureCell(
                "Drone Tuner",
                description: "Use drones to tune your instrument, improvise, and practice intonation.",
                icon: "tuningfork", color: Colors.lightBlue),
            FeatureCell(
                "Practice Reminders",
                description: "Create recurring practice notifications to remind you to practice.",
                icon: "alarm.fill", color: UIColor.systemPurple),
            FeatureCell(
                "Journal folders",
                description: "Keep your Journal organized with folders. You can keep a folder for lesson notes, pieces you're working on, general thoughts, or whatever you want!",
                icon: "folder.fill", color: Colors.sessionsColor),
            FeatureCell(
                "Export practice log",
                description: "Export your practice sessions as a .csv file. With a .csv file, you have the freedom to analyze and visualize your practice data however you want.",
                icon: "arrow.up.doc.fill", color: Colors.green),
            FeatureCell(
                "Support the developer",
                description: "I'm a musician in college - I originally made this app to help me with my violin practice. Your support is hugely appreciated!",
                icon: "heart.fill", color: UIColor("#FD606D"))
        ]
        
        cells.forEach { scrollView.addSubview($0) }
        
        scrollView.addSubview(handleView)
    }
    
    @objc func didTapRestore() {
        let alert = CenterLoadingViewController(style: .indefinite)
        
        iapHelper.restorePurchase {
            self.present(alert, animated: false, completion: nil)
        } completion: {
            [weak self] (success) in
            guard let self = self else { return }
            
            alert.closeAction = {
                [weak self] in
                guard let self = self else { return }
                
                if success {
                    let alert = UIAlertController(title: "Success!", message: "Your purchase has been restored. Thanks for your support!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { (action) in
                        self.successAction?()
                        self.dismiss(animated: true, completion: nil)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
                else {
                    let alert = UIAlertController(title: "Can't restore purchase", message: nil, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Done", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
            
            alert.close(success: success)
            
            
        }

    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleView.transform = CGAffineTransform(translationX: 0, y: min(0, scrollView.contentOffset.y))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.frame = self.view.bounds
                
        let (_, margin) = view.constrainedWidth(435)
        
        let (_, margin2) = view.constrainedWidth(580)
        
        handleView.contextualFrame = CGRect(
            x: 0, y: 0, width: view.bounds.width, height: handleView.sizeThatFits(view.bounds.size).height)
        
        titleLabel.sizeToFit()
        titleLabel.center = CGPoint(x: scrollView.bounds.midX, y: 100)
        
        detailLabel.sizeToFit()
        detailLabel.center = CGPoint(
            x: scrollView.bounds.midX,
            y: titleLabel.frame.maxY + 20 + detailLabel.bounds.height/2)
        
        let height = detailView.sizeThatFits(CGSize(width: scrollView.bounds.width - margin, height: .infinity)).height
        detailView.frame = CGRect(
            x: margin, y: detailLabel.frame.maxY + 10,
            width: scrollView.bounds.width - margin*2,
            height: height)
        
        let purchaseButtonWidth = min(view.bounds.width - margin, 330)
        
        purchaseButton.frame = CGRect(
            x: scrollView.bounds.midX - purchaseButtonWidth/2,
            y: detailView.frame.maxY + 40,
            width: purchaseButtonWidth,
            height: 52)
        purchaseButton.cornerRadius = purchaseButton.bounds.height/2
        
        spinner.frame = CGRect(
            x: 8, y: 0, width: 52, height: 52)
        
        restoreButton.sizeToFit()
        restoreButton.center = CGPoint(
            x: purchaseButton.frame.midX,
            y: purchaseButton.frame.maxY + 30)
        
        let deviceAspect = devicesImage.image!.size.height / devicesImage.image!.size.width
        
        devicesImage.frame = CGRect(
            x: margin2, y: restoreButton.frame.maxY + 30,
            width: view.bounds.width - margin2*2,
            height: (view.bounds.width - margin2*2)*deviceAspect)
        
        var minY: CGFloat = devicesImage.frame.maxY + 30 + Constants.smallMargin
        let cellWidth: CGFloat = view.bounds.width - Constants.smallMargin*2
        cells.forEach { (cell) in
            let height = cell.sizeThatFits(CGSize(width: cellWidth, height: .infinity)).height
            cell.bounds.size.width = cellWidth
            cell.bounds.size.height = height
            cell.frame.origin = CGPoint(x: view.bounds.midX - cellWidth/2, y: minY)
            minY += cell.bounds.height + Constants.smallMargin
        }
        
        cellBGView.frame = CGRect(
            from: CGPoint(x: 0, y: devicesImage.frame.maxY + 30),
            to: CGPoint(x: view.bounds.width, y: cells.last!.frame.maxY + 500))
        
        scrollView.contentSize.height = cells.last!.frame.maxY + 20 + view.safeAreaInsets.bottom
        
    }
    
}

fileprivate class FeatureCell: MaskedShadowView {
    
    private let iconView = IconView()
    private let label = UILabel()
    private let textView = UITextView()
        
    init(_ title: String?, description: String, icon: String, color: UIColor?) {
        super.init()
        
        if let image = UIImage(name: icon, pointSize: 17, weight: .semibold) {
            iconView.icon = image
            iconView.iconSize = image.size
        } else {
            iconView.icon = UIImage(named: icon)
            if icon == "JournalFill" {
                iconView.iconSize = CGSize(20)
            } else {
                iconView.iconSize = CGSize(24)
            }
        }
        
        roundCorners(12)
        
        iconView.backgroundColor = color
        iconView.iconColor = Colors.white
        
        addSubview(iconView)
        
        label.text = title
        label.font = Fonts.semibold.withSize(20)
        label.textColor = color
        addSubview(label)
        
        textView.font = Fonts.regular.withSize(17)
        textView.textColor = Colors.text.withAlphaComponent(0.9)
        textView.text = description
        textView.isEditable = false
        textView.textContainerInset.left = Constants.margin - 5
        textView.textContainerInset.right = Constants.margin - 5
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        addSubview(textView)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: 100 + textView.sizeThatFits(size).height + Constants.margin)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let size = Constants.iconBGSize.width + 4
        iconView.frame = CGRect(
            x: Constants.margin,
            y: Constants.margin,
            width: size, height: size)
        iconView.roundCorners(Constants.iconBGCornerRadius)
        
        label.frame = CGRect(
            x: Constants.margin, y: iconView.frame.maxY + 14,
            width: bounds.width - Constants.margin*2,
            height: 22
        )
        
        textView.frame = CGRect(x: 0, y: label.frame.maxY, width: bounds.width, height: textView.sizeThatFits(bounds.size).height)
        
    }
    
}

//
//  PracticeSessionsCell.swift
//  Andante
//
//  Created by Miles Vinson on 7/23/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import UIKit
import Combine

class PracticeSessionCollectionCell: UICollectionViewCell {
    public var session: CDSession!
    
    public let bgView = MaskedShadowView()
    public let sessionView = PracticeSessionView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .clear
        
        self.addSubview(bgView)
        bgView.addSubview(sessionView)
        
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                bgView.pushDown()
            }
            else {
                UIView.animate(withDuration: 0.2) {
                    self.bgView.pushUp()
                }
            }
        }
    }
    
    
    public func setSession(_ session: CDSession, checkToday: Bool = true) {
        self.session = session
              
        sessionView.setSession(session, checkToday: checkToday)
    }
    
    public func setSearchText(_ text: String) {
        sessionView.setSearchText(text)
    }
    
    public func bounce() {
        UIView.animate(withDuration: 0.15, delay: 0.1, options: .curveEaseIn, animations: {
            self.bgView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }) { (complete) in
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                self.bgView.transform = .identity
            }, completion: nil)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let frame = self.bounds.insetBy(dx: 4, dy: 4)
        bgView.center = frame.center
        bgView.bounds.size = frame.size
        sessionView.frame = bgView.bounds
                        
    }
    
}

class PracticeSessionCell: UITableViewCell {
    
    public var session: CDSession!
    
    public let bgView = MaskedShadowView()
    public let sessionView = PracticeSessionView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = .clear
        self.selectionStyle = .none
        
        self.addSubview(bgView)
        bgView.addSubview(sessionView)
          
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            bgView.pushDown()
        }
        else {
            UIView.animate(withDuration: 0.2) {
                self.bgView.pushUp()
            }
        }
    }
    
    public func setSession(_ session: CDSession, checkToday: Bool = true) {
        self.session = session
        
        sessionView.setSession(session, checkToday: checkToday)
    }
    
    public func setSearchText(_ text: String) {
        sessionView.setSearchText(text)
    }
    
    public func bounce() {
        UIView.animate(withDuration: 0.15, delay: 0.1, options: .curveEaseIn, animations: {
            self.bgView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }) { (complete) in
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                self.bgView.transform = .identity
            }, completion: nil)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let frame = self.bounds.insetBy(dx: Constants.smallMargin, dy: 4)
        bgView.center = frame.center
        bgView.bounds.size = frame.size
        sessionView.frame = bgView.bounds
                        
    }
    
}

class MaskedShadowView: UIView {
    
    public var transformScale: CGFloat = 0.95
    
    public var fgView = UIView()
    static var ShadowColor: UIColor {
        return Colors.dynamicColor(light: UIColor("#7D7DE0"), dark: .black)
    }
    
    public var extraShadowOpacity: Float = 0 {
        didSet {
            updateShadow()
        }
    }
    
    public var shadowColor: UIColor = ShadowColor {
        didSet {
            updateShadow()
        }
    }
    
    init() {
        super.init(frame: .zero)
                
        fgView.backgroundColor = Colors.foregroundColor
        updateShadow()
        self.addSubview(fgView)
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateShadow()
    }
    
    private func updateShadow() {
        fgView.setShadow(radius: 9, yOffset: 3, opacity: 0, color: shadowColor)

        if traitCollection.userInterfaceStyle == .dark {
            fgView.layer.shadowOpacity = 0.06 + extraShadowOpacity
        }
        else {
            fgView.layer.shadowOpacity = 0.06 + extraShadowOpacity
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func addSubview(_ view: UIView) {
        if view == fgView {
            super.addSubview(view)
        }
        else {
            fgView.addSubview(view)
        }
    }
    
    override func insertSubview(_ view: UIView, at index: Int) {
        fgView.insertSubview(view, at: index)
    }
    
    override var backgroundColor: UIColor? {
        get {
            return fgView.backgroundColor
        }
        set {
            fgView.backgroundColor = newValue
        }
    }
    
    public var cornerRadius: CGFloat = 10 {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        fgView.center = self.bounds.center
        fgView.bounds.size = self.bounds.size
        fgView.roundCorners(self.cornerRadius)
        
        fgView.layer.shadowPath = UIBezierPath(
            roundedRect: fgView.bounds,
            cornerRadius: fgView.layer.cornerRadius).cgPath
        
    }
    
    public func pushDown() {
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            self.fgView.transform = CGAffineTransform(scaleX: self.transformScale, y: self.transformScale)
        }, completion: nil)
    }
    
    public func pushUp() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            self.fgView.transform = .identity
        }, completion: nil)
    }
    
    override var transform: CGAffineTransform {
        get {
            return fgView.transform
        }
        set {
            fgView.transform = newValue
        }
    }
}


extension CGRect {
    public var center: CGPoint {
        return CGPoint(x: self.midX, y: self.midY)
    }
}

class PracticeSessionView: UIView {
    
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let timeLabel = UILabel()
    
    private var session: CDSession!
    
    private let notesView = UIImageView()
    private let recordingView = UIImageView()
    private let favoriteView = UIImageView()
    
    public let iconView = ProfileImageView()
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = .clear
                
        iconView.backgroundColor = Colors.lightColor
        self.addSubview(iconView)
                
        self.addSubview(titleLabel)
        titleLabel.font = Fonts.semibold.withSize(16)
        titleLabel.textColor = Colors.text
        
        self.addSubview(detailLabel)
        detailLabel.font = Fonts.medium.withSize(16)
        detailLabel.textColor = Colors.lightText
        
        self.addSubview(timeLabel)
        timeLabel.font = Fonts.medium.withSize(15)
        timeLabel.textColor = Colors.text
        
        self.addSubview(recordingView)
        recordingView.isHidden = true
        recordingView.image = UIImage(named: "mic")
        recordingView.tintColor = Colors.lightText
        
        self.addSubview(notesView)
        notesView.isHidden = true
        notesView.image = UIImage(named: "speech.bubble")
        notesView.tintColor = Colors.lightText
        
        self.addSubview(favoriteView)
        favoriteView.isHidden = true
        favoriteView.image = UIImage(named: "heart")
        favoriteView.tintColor = Colors.lightText
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                      
        timeLabel.sizeToFit()
               
        let titleSize = titleLabel.sizeThatFits(self.bounds.size)
        let detailSize = detailLabel.sizeThatFits(self.bounds.size)
        let padding: CGFloat = 2

        let combinedHeight = titleSize.height + detailSize.height + padding
        let minY = self.bounds.height/2 - combinedHeight/2

        let width = self.bounds.width - Constants.margin*2
               
        iconView.frame = CGRect(x: Constants.smallMargin, y: self.bounds.midY - 23,
                                       width: 46, height: 46)
               
        titleLabel.frame = CGRect(from: CGPoint(x: iconView.frame.maxX + 16,
                                                y: minY),
                                    to: CGPoint(x: self.bounds.maxX - Constants.margin - timeLabel.bounds.width - 16,
                                                y: minY + titleSize.height))

        detailLabel.frame = CGRect(x: titleLabel.frame.minX,
                                    y: titleLabel.frame.maxY + padding,
                                    width: width,
                                    height: detailSize.height).integral
        
        
        timeLabel.center = CGPoint(x: self.bounds.maxX - Constants.margin - timeLabel.bounds.width/2, y: titleLabel.center.y)
               
        layoutIcons()
        
    }
    
    func layoutIcons() {
        notesView.bounds.size = CGSize(21)
        recordingView.bounds.size = CGSize(21)
        favoriteView.bounds.size = CGSize(21)
        
        notesView.center = CGPoint(
            x: self.bounds.maxX - Constants.smallMargin - notesView.bounds.width/2,
            y: detailLabel.frame.midY+1)
        
        recordingView.center = CGPoint(
            x: self.bounds.maxX - Constants.smallMargin - recordingView.bounds.width/2,
            y: detailLabel.frame.midY+1)
        
        favoriteView.center = CGPoint(
            x: self.bounds.maxX - Constants.smallMargin - favoriteView.bounds.width/2,
            y: detailLabel.frame.midY+1)
        
        var visibleIcons: [UIImageView] = []
        if session.isFavorited { visibleIcons.append(favoriteView) }
        if session.hasRecording { visibleIcons.append(recordingView) }
        if session.hasNotes { visibleIcons.append(notesView) }
                
        for (i, icon) in visibleIcons.enumerated() {
            
            if i == 0 {
                icon.transform = .identity
            }
            else if i == 1 {
                let leftEdge = visibleIcons[0].bounds.width/2
                icon.transform = CGAffineTransform(
                    translationX: -(leftEdge + 1 + icon.bounds.width/2), y: 0)
            }
            else if i == 2 {
                let leftEdge = visibleIcons[0].bounds.width/2
                let midSize = visibleIcons[1].bounds.width
                icon.transform = CGAffineTransform(
                    translationX: -(leftEdge + 2 + midSize + icon.bounds.width/2), y: 0)
            }
            
        }
        
    }
           
    private var cancellables = Set<AnyCancellable>()
    
    private func reloadUI() {
        guard let session = self.session else { return }
        
        self.titleLabel.attributedText = NSAttributedString(string: session.getTitle(), attributes: [.kern : 0])
        self.detailLabel.text = "\(session.practiceTime) min"
        self.timeLabel.text = session.startTime.string(timeStyle: .short)
        self.notesView.isHidden = session.hasNotes == false
        self.recordingView.isHidden = session.hasRecording == false
        self.favoriteView.isHidden = session.isFavorited == false
        
        self.setNeedsLayout()
    }
    
    public func setSession(_ session: CDSession, checkToday: Bool = true) {
        self.session = session
        
        iconView.profile = session.profile
        
        cancellables.removeAll()
        
        session.objectWillChange.sink {
            [weak self] _ in
            guard let self = self else { return }
            self.reloadUI()
            
        }.store(in: &cancellables)
        
        reloadUI()
        
    }
    
    public func setFavorite(_ favorite: Bool) {
        if favorite == !favoriteView.isHidden { return }
        
        if favorite {
            favoriteView.alpha = 0
            favoriteView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            
            favoriteView.isHidden = false
            UIView.animate(withDuration: 0.45, delay: 0.25, usingSpringWithDamping: 0.92, initialSpringVelocity: 0, options: [], animations: {
                self.favoriteView.alpha = 1
                self.layoutIcons()
            }, completion: nil)
        }
        else {
            UIView.animate(withDuration: 0.45, delay: 0.25, usingSpringWithDamping: 0.92, initialSpringVelocity: 0, options: [], animations: {
                self.layoutIcons()
                self.favoriteView.alpha = 0
                self.favoriteView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            }, completion: { complete in
                self.favoriteView.isHidden = true
            })
        }
        
        setNeedsLayout()
    }
    
    private func setNotesHighlighted(_ highlighted: Bool) {
        if highlighted {
            notesView.tintColor = Colors.orange
        } else {
            notesView.tintColor = Colors.lightText
        }
    }
       
    public func setSearchText(_ text: String) {
        if text.isEmpty {
            setNotesHighlighted(false)
            return
        }
        
        var foundInTitle = false
        for word in session.getTitle().split(separator: " ") {
            if word.hasPrefix(text) {
                foundInTitle = true
                break
            }
        }
        
        setNotesHighlighted(foundInTitle == false)
        
    }
       
}

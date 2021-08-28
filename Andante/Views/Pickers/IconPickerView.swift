//
//  IconPickerView.swift
//  Andante
//
//  Created by Miles Vinson on 7/24/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class IconPickerView: UIView {
    
    private let iconData: [String] = [
        "violin", "cello", "acoustic-guitar", "ukulele", "banjo",
        "piano", "accordion", "harp", "electric-guitar", "singing",
        "flute", "oboe", "clarinet", "recorder", "bassoon",
        "trumpet", "trombone", "french-horn", "tuba", "saxophone",
        "snare-drum", "timpani", "xylophone", "marimba", "drum-set",
        "conducting-baton", "composing", "synthesizer", "kalimba", "pen",
        "music", "treble-clef", "alto-clef", "bass-clef", "paint-brush"]
    
    private var iconButtons: [IconButton] = []
    
    public var selectionAction: ((String)->Void)?
    
    public var selectedIcon: String? {
        didSet {
            for button in iconButtons {
                setButton(button, selected: iconData[button.tag] == selectedIcon)
            }
        }
    }
    
    private let selectionFeedback = UIImpactFeedbackGenerator(style: .light)
    
    init() {
        super.init(frame: .zero)
        
        selectionFeedback.prepare()
        
        for (i, iconName) in iconData.enumerated() {
            
            let iconButton = IconButton()
            iconButton.tag = i
            iconButton.iconName = iconName + "-sm"
            self.addSubview(iconButton)
            iconButtons.append(iconButton)
            
            iconButton.iconView.layer.borderWidth = 2
            
            setButton(iconButton, selected: iconName == selectedIcon)
            
            iconButton.action = {
                [weak self] in
                guard let self = self else { return }
                self.selectedIcon = self.iconData[iconButton.tag]
                
                for button in self.iconButtons {
                    self.setButton(button, selected: button == iconButton)
                }
                
                self.selectionAction?(self.iconData[iconButton.tag])
                
                self.selectionFeedback.impactOccurred()
            }
            
        }
        
    }
    
    fileprivate func setButton(_ button: IconButton, selected: Bool) {
        if selected {
            button.iconView.layer.borderColor = Colors.orange.withAlphaComponent(0.75).cgColor
            button.iconView.setShadow(radius: 6, yOffset: 3, opacity: 0.075)
        } else {
            button.iconView.layer.borderColor = UIColor.clear.cgColor
            button.iconView.setShadow(radius: 6, yOffset: 3, opacity: 0)
        }
    }
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        for button in iconButtons {
            setButton(button, selected: iconData[button.tag] == selectedIcon)
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let columns: CGFloat = 5
        let rows: CGFloat = 7
        let width = size.width
        let itemSize = width/columns
        return CGSize(width: size.width, height: rows * itemSize + 20)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let margin: CGFloat = 0
        
        let columns: CGFloat = 5
        
        let width = self.bounds.width - margin*2
        let itemSize = width/columns
        
        for (i, item) in iconButtons.enumerated() {
            
            let x = CGFloat(i).truncatingRemainder(dividingBy: columns) * itemSize
            let y = floor(CGFloat(CGFloat(i)/columns)) * (itemSize + 4)
            
            item.frame = CGRect(
                x: margin + x, y: y,
                width: itemSize,
                height: itemSize)
            
        }
        
        
    }
    
}

fileprivate class IconButton: PushButton {
    
    public let iconView = IconView()
    public var iconName: String = "" {
        didSet {
            iconView.icon = UIImage(named: iconName)
        }
    }
    
    override init() {
        super.init()
        
        iconView.backgroundColor = Colors.lightColor
        iconView.iconInsets = UIEdgeInsets(10)
        self.addSubview(iconView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        iconView.frame = self.bounds.insetBy(dx: 6, dy: 6)
        iconView.roundCorners(prefersContinuous: false)
        
    }
}

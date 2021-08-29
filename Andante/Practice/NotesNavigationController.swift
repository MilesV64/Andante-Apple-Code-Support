//
//  NotesNavigationController.swift
//  Andante
//
//  Created by Miles Vinson on 6/7/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class NotesNavigationController: UINavigationController {
    
    private let headerView = Separator()
    
    static var headerHeight: CGFloat = 130
    
    private let doneButton = UIButton(type: .system)
    private let segmentedControl = SegmentedControl()
    
    init() {
        super.init(rootViewController: NotesViewController())
        
        //self.modalPresentationCapturesStatusBarAppearance = true
        //self.modalPresentationStyle = .overCurrentContext
        
        self.setNavigationBarHidden(true, animated: false)
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerView.backgroundColor = Colors.foregroundColor
        headerView.color = Colors.barSeparator
        headerView.position = .bottom
        self.view.addSubview(headerView)
        
        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(Colors.orange, for: .normal)
        doneButton.titleLabel?.font = Fonts.semibold.withSize(17)
        doneButton.contentHorizontalAlignment = .right
        doneButton.contentEdgeInsets.right = Constants.margin + 2
        doneButton.addTarget(self, action: #selector(didSelectDone), for: .touchUpInside)
        headerView.addSubview(doneButton)
        
        //headerView.addSubview(segmentedControl)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        headerView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.safeAreaInsets.top + NotesNavigationController.headerHeight)
        
        doneButton.frame = CGRect(x: headerView.bounds.maxX - 80, y: max(self.view.safeAreaInsets.top, 6), width: 80, height: 44)
        
        //segmentedControl.frame = CGRect(x: Constants.smallMargin, y: headerView.bounds.maxY - 18 - 54, width: headerView.bounds.width - Constants.smallMargin*2, height: 54)
                
    }
    
    @objc func didSelectDone() {
        self.dismiss(animated: true, completion: nil)
    }
}

protocol SegmentedControlDelegate: class {
    func segmentedControlDidSelect(option: Int)
}

class SegmentedControl: UIView {
    
    public weak var delegate: SegmentedControlDelegate?
    
    private let firstOption = PushButton()
    private let secondOption = PushButton()
    
    private let highlightView = UIView()
    
    private var selectedOption = 0
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = Colors.lightColor
        
        highlightView.backgroundColor = Colors.orange
        highlightView.setShadow(radius: 6, yOffset: 2, opacity: 0.16)
        self.addSubview(highlightView)
        
        firstOption.setTitle("Notes", color: Colors.white, font: Fonts.semibold.withSize(17))
        firstOption.action = {
            self.switchState()
        }
        firstOption.isUserInteractionEnabled = false
        self.addSubview(firstOption)
        
        secondOption.setTitle("Journal", color: Colors.text, font: Fonts.medium.withSize(17))
        secondOption.action = {
            self.switchState()
        }
        self.addSubview(secondOption)
        
        
        
    }
    
    func switchState() {
        selectedOption = selectedOption == 0 ? 1 : 0
        delegate?.segmentedControlDidSelect(option: selectedOption)
        
        if selectedOption == 0 {
            firstOption.isUserInteractionEnabled = false
            secondOption.isUserInteractionEnabled = true
        }
        else {
            firstOption.isUserInteractionEnabled = true
            secondOption.isUserInteractionEnabled = false
        }
        
        UIView.animateWithCurve(duration: 0.5, x1: 0.16, y1: 1, x2: 0.3, y2: 1, animation: {
            self.layoutSubviews()
        }, completion: nil)
        
        UIView.transition(with: firstOption, duration: 0.15, options: .transitionCrossDissolve, animations: {
            if self.selectedOption == 0 {
                self.firstOption.setTitle("Notes", color: Colors.white, font: Fonts.semibold.withSize(17))
            }
            else {
                self.firstOption.setTitle("Notes", color: Colors.text, font: Fonts.medium.withSize(17))
            }
        }, completion: nil)
        
        UIView.transition(with: secondOption, duration: 0.15, options: .transitionCrossDissolve, animations: {
            if self.selectedOption == 1 {
                self.secondOption.setTitle("Journal", color: Colors.white, font: Fonts.semibold.withSize(17))
            }
            else {
                self.secondOption.setTitle("Journal", color: Colors.text, font: Fonts.medium.withSize(17))
            }
        }, completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.roundCorners()
        
        firstOption.frame = CGRect(x: 0, y: 0, width: self.bounds.width/2, height: self.bounds.height)
        
        secondOption.frame = CGRect(x: self.bounds.midX, y: 0, width: self.bounds.width/2, height: self.bounds.height)
        
        highlightView.frame = firstOption.frame.offsetBy(dx: CGFloat(selectedOption) * self.bounds.width/2, dy: 0)
        highlightView.roundCorners()
        
    }
}


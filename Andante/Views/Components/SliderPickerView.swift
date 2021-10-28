//
//  SliderPickerView.swift
//  Andante
//
//  Created by Miles on 10/27/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

protocol SegmentedPickerOptionView: UIView {
    
    /// Customize selection look
    func setSelected(_ selected: Bool)
    
}

protocol SegmentedPickerViewDelegate: AnyObject {
    func segmentedPickerView(_ view: SegmentedPickerView, didSelectOptionAt index: Int)
}

class SegmentedPickerView: UIView, UIGestureRecognizerDelegate {
    
    public weak var delegate: SegmentedPickerViewDelegate?
    
    private static let padding: CGFloat = 3
    
    private var optionViews: [SegmentedPickerOptionView] = []
    
    private let selectedBackgroundView: UIView = {
        let v = UIView()
        v.backgroundColor = Colors.orange
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.1
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 5
        return v
    }()
    
    private(set) var selectedOption: Int = 0
    
    
    // MARK: - Gestures
    
    private let pressGesture = UILongPressGestureRecognizer()
    private let panGesture = UIPanGestureRecognizer()
    
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = Colors.lightColor
        self.addSubview(self.selectedBackgroundView)
        
        self.pressGesture.minimumPressDuration = 0
        self.pressGesture.addTarget(self, action: #selector(self.handlePressGesture))
        self.pressGesture.delegate = self
        self.addGestureRecognizer(self.pressGesture)
        
        self.panGesture.addTarget(self, action: #selector(self.handlePanGesture))
        self.panGesture.delegate = self
        self.addGestureRecognizer(self.panGesture)
        
        
        
    }
    
    
    // MARK: - Insert/Select
    
    public func insertOption(_ optionView: SegmentedPickerOptionView, at index: Int) {
        optionView.setSelected(index == self.selectedOption)
        self.optionViews.insert(optionView, at: index)
        self.addSubview(optionView)
        self.setNeedsLayout()
    }
    
    private func _selectOption(at index: Int, animated: Bool = true) {
        if self.selectedOption != index {
            self.delegate?.segmentedPickerView(self, didSelectOptionAt: index)
        }
        
        self.selectOption(at: index, animated: animated)
    }
    
    public func selectOption(at index: Int, animated: Bool = true) {
        guard index >= 0, index < self.optionViews.count else { return }
        
        self.selectedOption = index
        
        let animator = UIViewPropertyAnimator(
            duration: animated ? 0.3 : 0,
            controlPoint1: CGPoint(x: 0.25, y: 1),
            controlPoint2: CGPoint(x: 0.5, y: 1),
            animations: {
                self.layoutSelectedBackgroundView()
                for (i, view) in self.optionViews.enumerated() {
                    view.setSelected(i == index)
                }
            })
        
        animator.startAnimation()
        
    }
    
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard self.optionViews.count > 0 else { return }
        
        self.roundCorners(self.bounds.height / 2, prefersContinuous: true)
        
        let insetRect = self.bounds.insetBy(dx: Self.padding, dy: Self.padding)
        
        let itemWidth = insetRect.width / CGFloat(self.optionViews.count)
        var minX: CGFloat = insetRect.minX
        for view in self.optionViews {
            view.bounds.size = CGSize(width: itemWidth, height: insetRect.height)
            view.center = CGPoint(x: minX + (itemWidth / 2), y: insetRect.midY)
            minX += itemWidth
        }
        
        if !self.isDraggingSelectedView {
            self.layoutSelectedBackgroundView()
        }
        
    }
    
    private func layoutSelectedBackgroundView() {
        let selectedView = self.optionViews[self.selectedOption]
        self.selectedBackgroundView.bounds.size = selectedView.bounds.size
        self.selectedBackgroundView.center = selectedView.center
        self.selectedBackgroundView.roundCorners(selectedView.bounds.height / 2)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Gestures
    
    private var isDraggingSelectedView: Bool = false
    private var initialTouchLocation: CGPoint = .zero
    
    @objc private func handlePanGesture() {
        let location = self.panGesture.location(in: self)
        
        if self.panGesture.state == .began {
            
            self.initialTouchLocation = location
            
            if self.optionViewContainsTouch(optionView: self.optionViews[self.selectedOption], touchPt: location) {
                self.isDraggingSelectedView = true
            }
            else {
                self.isDraggingSelectedView = false
            }
            
        }
        else if self.panGesture.state == .changed {
            guard self.isDraggingSelectedView else { return }
            guard self.optionViews.count == 2 else { return }
                        
            for (i, view) in self.optionViews.enumerated() {
                if self.optionViewContainsTouch(optionView: view, touchPt: location) {
                    view.setSelected(true)
                    if self.selectedBackgroundView.center.x != view.center.x {
                        UISelectionFeedbackGenerator().selectionChanged()

                        let animator = UIViewPropertyAnimator(
                            duration: 0.3,
                            controlPoint1: CGPoint(x: 0.25, y: 1),
                            controlPoint2: CGPoint(x: 0.5, y: 1),
                            animations: {
                                self.selectedBackgroundView.bounds.size.width = view.bounds.size.width
                                self.selectedBackgroundView.center.x = view.center.x
                                self.setBackgroundTransform(forCurrentlyHighlightedOption: i)
                            })
                        
                        animator.startAnimation()
                    }
                }
                else {
                    view.setSelected(false)
                }
            }
        }
        else {
            if self.isDraggingSelectedView {
                self.isDraggingSelectedView = false
                
                let velocity = self.panGesture.velocity(in: self).x
                
                if self.selectedOption == 0, velocity > 300 {
                    self._selectOption(at: 1)
                }
                else if self.selectedOption == 1, velocity < -300 {
                    self._selectOption(at: 0)
                }
                else {
                    for (i, view) in self.optionViews.enumerated() {
                        if self.optionViewContainsTouch(optionView: view, touchPt: location) {
                            self._selectOption(at: i)
                            break
                        }
                    }
                }
            }
        }
    }
    
    @objc func handlePressGesture() {
        let location = self.pressGesture.location(in: self)
        
        if self.pressGesture.state == .began {
            if self.optionViewContainsTouch(optionView: self.optionViews[self.selectedOption], touchPt: location) {
                UIView.animate(withDuration: 0.25) {
                    self.setBackgroundTransform(forCurrentlyHighlightedOption: self.selectedOption)
                }
            }
        }
        else if self.pressGesture.state != .changed {
            if !self.isDraggingSelectedView {
                for (i, view) in self.optionViews.enumerated() {
                    if view.contextualFrame.contains(location) {
                        self._selectOption(at: i)
                        break
                    }
                }
            }
            
            UIView.animate(withDuration: 0.25) {
                self.selectedBackgroundView.transform = .identity
                self.optionViews.forEach { $0.transform = .identity }
            }
            
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === self.panGesture, otherGestureRecognizer === self.pressGesture {
            return true
        }
        else if gestureRecognizer === self.pressGesture, otherGestureRecognizer === self.panGesture {
            return true
        }
        return false
    }
    
    
    // MARK: - Helpers
    
    private func setBackgroundTransform(forCurrentlyHighlightedOption option: Int) {
        let scale: CGFloat = 0.95
        let heightDiff = (self.selectedBackgroundView.bounds.height * (1 - scale)) / 2
        let widthDiff = (self.selectedBackgroundView.bounds.width * (1 - scale)) / 2
        let translation = widthDiff - heightDiff
        let mod: CGFloat = option == 0 ? -1 : 1
        
        let transform = CGAffineTransform(scaleX: scale, y: scale).concatenating(CGAffineTransform(translationX: translation * mod, y: 0))
        
        self.selectedBackgroundView.transform = transform
        
        for (i, view) in self.optionViews.enumerated() {
            if i == option {
                view.transform = transform
            } else {
                view.transform = .identity
            }
        }
    }
    
    private func frameFromBoundsAndCenter(view: UIView) -> CGRect {
        return CGRect(
            x: view.center.x - (view.bounds.width / 2),
            y: view.center.y - (view.bounds.height / 2),
            width: view.bounds.width,
            height: view.bounds.height)
    }
    
    private func optionViewContainsTouch(optionView: UIView, touchPt: CGPoint) -> Bool {
        let minX = optionView.center.x - (optionView.bounds.width / 2)
        let maxX = optionView.center.x + (optionView.bounds.width / 2)
        
        return touchPt.x >= minX && touchPt.x < maxX
    }
}


// MARK: - Option Views

extension SegmentedPickerView {
    class StandardOptionView: UIView, SegmentedPickerOptionView {
        
        let label = UILabel()
        
        init(title: String) {
            super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
            
            self.label.text = title
            self.label.font = Fonts.semibold.withSize(16)
            self.label.textAlignment = .center
            self.addSubview(self.label)
            
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.label.frame = self.bounds
            
        }
        
        func setSelected(_ selected: Bool) {
            if selected {
                self.label.textColor = Colors.text
            }
            else {
                self.label.textColor = Colors.text.withAlphaComponent(0.3)
            }
        }
        
    }

}

//
//  TimePickerView.swift
//  Andante
//
//  Created by Miles Vinson on 7/7/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class TimePickerSource: UIView {
    public var date: Date {
        set {
            
        }
        get {
            return Date()
        }
    }
    public weak var delegate: PickerViewDelegate?
}

class TimePickerView: UIView {
    
    public weak var delegate: PickerViewDelegate? {
        didSet {
            view.delegate = delegate
        }
    }
    
    private var view: TimePickerSource!
    
    public var date: Date {
        set {
            view.date = newValue
        }
        get {
            return view.date
        }
    }
    
    init() {
        
        if Settings.standardTime {
            view = StandardTimePickerView()
        }
        else {
            view = AMPMTimePickerView()
        }
        
        super.init(frame: .zero)
        
        self.addSubview(view)
        
    }
    
    @discardableResult
    override func becomeFirstResponder() -> Bool {
        view.becomeFirstResponder()
    }
    
    @discardableResult
    override func resignFirstResponder() -> Bool {
        view.resignFirstResponder()
    }
    
    override var isFirstResponder: Bool {
        return view.isFirstResponder
    }
        
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return view.sizeThatFits(size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        view.frame = self.bounds
        
    }
}

//MARK: Standard
class StandardTimePickerView: TimePickerSource, UITextFieldDelegate {
    
    private let button = CustomButton()
    private let textField = UnselectableTextField()
    
    private var hour = 12
    private var min = 0
    
    override var date: Date {
        set {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: newValue)
            let min = calendar.component(.minute, from: newValue)
            
            var array: [Int] = []
            if hour < 10 {
                array.append(contentsOf: [0, hour])
            }
            else {
                array.append(contentsOf: [hour.num(0), hour.num(1)])
            }
            
            if min < 10 {
                array.append(contentsOf: [0, min])
            }
            else {
                array.append(contentsOf: [min.num(0), min.num(1)])
            }
            
            self.hour = hour
            self.min = min
            
            backingText = array
            
            setText()
            
        }
        get {
            updateHourMin()
            
            return Calendar.current.date(
                bySettingHour: self.hour,
                minute: self.min, second: 0, of: Date()) ?? Date()
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        button.backgroundColor = Colors.lightColor
        button.roundCorners(7)
        
        button.highlightAction = { isHighlighted in
            if isHighlighted {
                self.textField.alpha = 0.2
            }
            else {
                UIView.animate(withDuration: 0.2) {
                    self.textField.alpha = 1
                }
            }
        }
        
        button.action = {
            self.delegate?.pickerViewWillBeginEditing?(self)
            self.textField.isUserInteractionEnabled = true
            self.becomeFirstResponder()
        }
        
        self.addSubview(button)
        
        textField.text = ""
        textField.isUserInteractionEnabled = false
        textField.textColor = Colors.text
        textField.font = Fonts.medium.withSize(17)
        textField.keyboardType = .numberPad
        textField.delegate = self
        textField.textAlignment = .right
        self.addSubview(textField)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    @discardableResult
    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    @discardableResult
    override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
    
    override var isFirstResponder: Bool {
        return textField.isFirstResponder
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: 76, height: 36)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        button.frame = CGRect(x: 0, y: 0, width: 76, height: 36)
        textField.frame = button.bounds.inset(by: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 14))
        
    }
    
    private var isFirstEdit = true
    func textFieldDidBeginEditing(_ textField: UITextField) {
        button.isUserInteractionEnabled = false

        textField.textColor = Colors.orange
        isFirstEdit = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        button.isUserInteractionEnabled = true
        textField.isUserInteractionEnabled = false

        textField.textColor = Colors.text
        
        updateHourMin()
        
        delegate?.pickerViewDidEndEditing?(self)

    }
    
    private func updateHourMin() {
        if backingText.count == 0 {
            hour = 0
            min = 0
        }
        else if backingText.count == 1 {
            hour = backingText[0]
            min = 0
        }
        else if backingText.count == 2 {
            let num = Int(backingText)
            if num <= 24 {
                hour = num == 24 ? 0 : num
                min = 0
            }
            else if backingText[0] <= 5 && backingText[1] <= 9 {
                hour = 0
                min = num
            }
            else if backingText[0] <= 9 && backingText[1] <= 5 {
                hour = backingText[0]
                min = backingText[1]*10
            }
        }
        else if backingText.count == 3 {
            hour = backingText[0]
            min = Int([backingText[1], backingText[2]])
        }
        else {
            let firstGroup = Int([backingText[0], backingText[1]])
            let secondGroup = Int([backingText[2], backingText[3]])
            
            if firstGroup == 24 {
                hour = 0
                min = secondGroup
            }
            else {
                hour = firstGroup
                min = secondGroup
            }
        }
        
        setText()
    }
    
    private var backingText: [Int] = []
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.delegate?.pickerViewDidEdit?(self)
        var newBackingText = backingText
        
        if isFirstEdit {
            if let num = Int(string) {
                newBackingText = [num]
            }
            else if string == "" {
                newBackingText = [0]
            }
            isFirstEdit = false
        }
        else {
            if let num = Int(string) {
                newBackingText.append(num)
            }
            else if string == "" {
                if backingText.count <= 1 {
                    newBackingText = []
                }
                else {
                    newBackingText.removeLast()
                }
            }
        }
        
        if isValidTimeNumber(newBackingText) {
            backingText = newBackingText
            
            switch newBackingText.count {
            case 1:
                textField.text = "\(newBackingText[0])"
            case 2:
                textField.text = "\(newBackingText[0])\(newBackingText[1])"
            case 3:
                textField.text = "\(newBackingText[0]):\(newBackingText[1])\(newBackingText[2])"
            case 4:
                textField.text = "\(newBackingText[0])\(newBackingText[1]):\(newBackingText[2])\(newBackingText[3])"
            default:
                textField.text = ""
            }
        }
                
        return false
    }
    
    private func isValidTimeNumber(_ nums: [Int]) -> Bool {
        if nums.count <= 1 {
            return true
        }
        else if nums.count == 2 {
            return (nums[0] <= 5 && nums[1] <= 9) || (nums[0] <= 9 && nums[1] <= 5)
        }
        else if nums.count == 3 {
            if nums[0] <= 9 && nums[1] <= 5 && nums[2] <= 9 {
                return true
            }
            else if Int([nums[0], nums[1]]) <= 24 && nums[2] <= 5 {
                return true
            }
        }
        else if nums.count == 4 {
            let firstGroup = Int([nums[0], nums[1]])
            let secondGroup = Int([nums[2], nums[3]])
            return firstGroup <= 24 && secondGroup <= 59
        }
        
        return false
        
    }
    
    private func setText() {
        let hourStr = String(format: "%02i", self.hour)
        let minStr = String(format: "%02i", self.min)
        self.textField.text = hourStr + ":" + minStr
    }
    
}


//MARK: AMPM
class AMPMTimePickerView: TimePickerSource, UITextFieldDelegate {
    
    private let button = CustomButton()
    private let textField = UnselectableTextField()
    
    private let ampmPicker = AMPMPickerView()
    private var hour = 12
    private var min = 0
    
    override var date: Date {
        set {
            let calendar = Calendar.current
            var hour = calendar.component(.hour, from: newValue)
            let min = calendar.component(.minute, from: newValue)
            if hour > 12 {
                ampmPicker.setValue(1)
                hour -= 12
            }
            else if hour == 12 {
                ampmPicker.setValue(1)
            }
            else if hour == 0 {
                ampmPicker.setValue(0)
                hour = 12
            }
            else {
                ampmPicker.setValue(0)
            }
            
            self.hour = hour
            self.min = min
            
            backingText = hour*100 + min
            
            setText()
            
        }
        get {
            updateHourMin()
            
            var hour = self.hour

            if ampmPicker.value == 1 && hour < 12 {
                hour += 12
            }
            else if ampmPicker.value == 0 && hour == 12 {
                hour = 0
            }
            
            return Calendar.current.date(
                bySettingHour: hour,
                minute: self.min, second: 0, of: Date()) ?? Date()
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        button.backgroundColor = Colors.lightColor
        button.roundCorners(7)
        
        button.highlightAction = { isHighlighted in
            if isHighlighted {
                self.textField.alpha = 0.2
            }
            else {
                UIView.animate(withDuration: 0.2) {
                    self.textField.alpha = 1
                }
            }
        }
        
        button.action = {
            self.delegate?.pickerViewWillBeginEditing?(self)
            self.textField.isUserInteractionEnabled = true
            self.becomeFirstResponder()
        }
        
        self.addSubview(button)
        
        textField.text = ""
        textField.isUserInteractionEnabled = false
        textField.textColor = Colors.text
        textField.font = Fonts.medium.withSize(17)
        textField.keyboardType = .numberPad
        textField.delegate = self
        textField.textAlignment = .right
        self.addSubview(textField)
        
        self.addSubview(ampmPicker)
        ampmPicker.changeHandler = {
            [weak self] in
            guard let self = self else { return }
            self.delegate?.pickerViewDidEdit?(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    @discardableResult
    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    @discardableResult
    override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
    
    override var isFirstResponder: Bool {
        return textField.isFirstResponder
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: 88 + 8 + 72, height: 36)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        button.frame = CGRect(x: 0, y: 0, width: 72, height: 36)
        textField.frame = button.bounds.inset(by: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 14))
        
        ampmPicker.bounds.size = CGSize(width: 88, height: 36)
        ampmPicker.frame.origin = CGPoint(x: self.bounds.maxX - ampmPicker.bounds.width, y: 0)
    }
    
    private var isFirstEdit = true
    func textFieldDidBeginEditing(_ textField: UITextField) {
        button.isUserInteractionEnabled = false

        textField.textColor = Colors.orange
        isFirstEdit = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        button.isUserInteractionEnabled = true
        textField.isUserInteractionEnabled = false

        textField.textColor = Colors.text
        
        updateHourMin()
        
        delegate?.pickerViewDidEndEditing?(self)

    }
    
    private func updateHourMin() {
        let nums = String(backingText).map { Int(String($0))! }
        
        if backingText == 0 {
            textField.text = "12:00"
            hour = 12
            min = 0
        }
        else if nums.count == 1 {
            textField.text = "\(nums[0]):00"
            hour = nums[0]
            min = 0
        }
        else if nums.count == 2 {
            if nums[0] == 1 && nums[1] <= 2 {
                textField.text = "\(nums[0])\(nums[1]):00"
                hour = nums[0]*10 + nums[1]
                min = 0
            }
            else {
                textField.text = "\(nums[0]):\(nums[1])0"
                hour = nums[0]
                min = nums[1]*10
            }
        }
        else if nums.count == 3 {
            hour = nums[0]
            min = nums[1]*10 + nums[2]
        }
        else if nums.count == 4 {
            hour = nums[0]*10 + nums[1]
            min = nums[2]*10 + nums[3]
        }
    }
    
    private var backingText = 0
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.delegate?.pickerViewDidEdit?(self)
        var newBackingText = backingText
        
        if isFirstEdit {
            if let num = Int(string) {
                newBackingText = num
            }
            else if string == "" {
                newBackingText = 0
            }
            isFirstEdit = false
        }
        else {
            if let num = Int(string) {
                newBackingText = backingText * 10 + num
            }
            else if string == "" {
                newBackingText = backingText / 10
            }
        }
        
        if isValidTimeNumber(newBackingText) {
            backingText = newBackingText
            
            let numString = String(backingText)
            let nums = numString.map { Int(String($0))! }
            
            switch nums.count {
            case 1:
                textField.text = nums[0] != 0 ? "\(nums[0])" : ""
            case 2:
                textField.text = "\(nums[0]):\(nums[1])"
            case 3:
                textField.text = "\(nums[0]):\(nums[1])\(nums[2])"
            case 4:
                textField.text = "\(nums[0])\(nums[1]):\(nums[2])\(nums[3])"
            default:
                textField.text = ""
            }
        }
                
        return false
    }
    
    private func isValidTimeNumber(_ num: Int) -> Bool {
        let string = String(num)
        let nums = string.map { Int(String($0))! }
        
        if nums.count == 1 {
            return true
        }
        else if nums.count == 2 {
            return nums[1] <= 5
        }
        else if nums.count == 3 {
            return nums[2] <= 9
        }
        else if nums.count == 4 {
            return nums[0] == 1 && nums[1] <= 2 && nums[2] <= 5
        }
        
        return false
        
    }
    
    private func setText() {
        let hourStr = String(self.hour)
        let minStr = String(format: "%02i", self.min)
        self.textField.text = hourStr + ":" + minStr
    }
    
}




//MARK: AMPMPickerView
fileprivate class AMPMPickerView: UIView {
    
    private let amButton = CustomButton()
    private let pmButton = CustomButton()
    
    private let selectionView = UIView()
    public var value = 0
    
    public func setValue(_ value: Int) {
        self.selectOption(value)
    }
    
    public var changeHandler: (()->Void)?
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = Colors.lightColor
        self.roundCorners(7)
        
        selectionView.backgroundColor = Colors.dynamicColor(
            light: Colors.foregroundColor,
            dark: Colors.text.withAlphaComponent(0.25))
        selectionView.setShadow(radius: 4, yOffset: 1, opacity: 0.08)
        selectionView.roundCorners(5)
        self.addSubview(selectionView)
        
        amButton.setTitle("AM", color: Colors.text, font: Fonts.medium.withSize(15))
        amButton.highlightAction = { isHighlighted in
            if isHighlighted {
                self.amButton.alpha = 0.2
            }
            else {
                UIView.animate(withDuration: 0.2) {
                    self.amButton.alpha = 1
                }
            }
        }
        amButton.action = {
            self.changeHandler?()
            self.selectOption(0)
        }
        self.addSubview(amButton)
        
        pmButton.setTitle("PM", color: Colors.text, font: Fonts.medium.withSize(15))
        pmButton.highlightAction = { isHighlighted in
            if isHighlighted {
                self.pmButton.alpha = 0.2
            }
            else {
                UIView.animate(withDuration: 0.2) {
                    self.pmButton.alpha = 1
                }
            }
        }
        pmButton.action = {
            self.changeHandler?()
            self.selectOption(1)
        }
        self.addSubview(pmButton)
        
        selectOption(0)
    }
    
    private func selectOption(_ option: Int) {
        self.value = option
        
        let selectedButton = option == 0 ? amButton : pmButton
        let unselectionButton = option == 0 ? pmButton : amButton
        
        selectedButton.isUserInteractionEnabled = false
        unselectionButton.isUserInteractionEnabled = true
        
        UIView.transition(with: selectedButton, duration: 0.15, options: .transitionCrossDissolve, animations: {
            selectedButton.titleLabel?.font = Fonts.semibold.withSize(15)
        }, completion: nil)
        
        UIView.transition(with: unselectionButton, duration: 0.15, options: .transitionCrossDissolve, animations: {
            unselectionButton.titleLabel?.font = Fonts.medium.withSize(15)
        }, completion: nil)
        
        UIView.animate(withDuration: 0.26, delay: 0, usingSpringWithDamping: 0.88, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            self.layoutSubviews()
        }, completion: nil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        amButton.frame = CGRect(
            x: 3, y: 0,
            width: self.bounds.width/2 - 3,
            height: self.bounds.height)
        
        pmButton.frame = CGRect(
            x: self.bounds.midX, y: 0,
            width: self.bounds.width/2 - 3,
            height: self.bounds.height)
        
        selectionView.frame = (value == 0 ? amButton : pmButton).frame.insetBy(dx: 1, dy: 4)
        
    }
}

extension Int {
    
    func num(_ position: Int) -> Int {
        let nums = String(self).map { Int(String($0))! }
        
        if position < 0 || position >= nums.count {
            return 0
        }
        else {
            return nums[position]
        }
    }
    
    init(_ nums: [Int]) {
        var string = ""
        nums.forEach { string += String($0) }
        
        self.init(Int(string) ?? 0)
    }
    
}

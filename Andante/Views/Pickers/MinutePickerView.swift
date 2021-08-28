//
//  MinutePickerView.swift
//  Andante
//
//  Created by Miles Vinson on 7/6/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

@objc protocol PickerViewDelegate: class {
    @objc optional func pickerViewWillBeginEditing(_ view: UIView)
    @objc optional func pickerViewDidEndEditing(_ view: UIView)
    @objc optional func pickerViewDidSelectSuggested(_ view: UIView)
    @objc optional func pickerViewDidSelectAnySuggested(_ view: UIView)
    @objc optional func pickerViewDidEdit(_ view: UIView)
}

class MinutePickerView: UIView, UITextFieldDelegate {
    
    public weak var delegate: PickerViewDelegate?
    
    public let button = CustomButton()
    private let textField = UnselectableTextField()
    private let minLabel = UILabel()
    private let toolbar = MinuteSuggestionsToolbar()
    
    enum Style {
        case inline, prominent
    }
    
    private var style: Style
    
    public var useSuggested = false {
        didSet {
            toolbar.useSuggested = useSuggested
        }
    }
    
    public var value: Int {
        set {
            _value = newValue
            textField.text = "\(value)"
        }
        get {
            return _value
        }
    }
    
    private var _value: Int = 30
        
    init(_ style: Style) {
        self.style = style
        
        super.init(frame: .zero)
        
        button.touchMargin = 8
        button.backgroundColor = self.style == .inline ? .clear : Colors.lightColor
        button.roundCorners(7)
        
        button.highlightAction = { isHighlighted in
            if isHighlighted {
                self.minLabel.alpha = 0.2
                self.textField.alpha = 0.2
            }
            else {
                UIView.animate(withDuration: 0.2) {
                    self.minLabel.alpha = 1
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
        
        minLabel.isUserInteractionEnabled = false
        minLabel.text = "min"
        minLabel.textColor = self.style == .inline ? Colors.orange : Colors.text
        minLabel.font = Fonts.medium.withSize(17)
        self.addSubview(minLabel)
        
        textField.text = "\(value)"
        textField.isUserInteractionEnabled = false
        textField.textColor = self.style == .inline ? Colors.orange : Colors.text
        textField.font = Fonts.medium.withSize(17)
        textField.keyboardType = .numberPad
        textField.delegate = self
        textField.textAlignment = .right
        
        toolbar.selectionHandler = { num, suggested in
            if suggested {
                self.delegate?.pickerViewDidSelectSuggested?(self)
            }
            else {
                self.value = num
            }
            self.delegate?.pickerViewDidSelectAnySuggested?(self)
            self.resignFirstResponder()
            self.delegate?.pickerViewDidEdit?(self)
        }
        textField.inputAccessoryView = toolbar

        
        self.addSubview(textField)
        
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
        return CGSize(width: 93, height: 36)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        button.frame.origin = .zero
        button.bounds.size = CGSize(width: 93, height: 36)
        let minWidth = minLabel.sizeThatFits(self.bounds.size).width
        minLabel.frame = CGRect(
            x: button.bounds.maxX - minWidth - 14,
            y: 0,
            width: minWidth,
            height: button.bounds.height - 0.5)
        
        textField.frame = CGRect(
            from: CGPoint(x: 10, y: 1),
            to: CGPoint(x: minLabel.frame.minX - 6, y: button.bounds.maxY))
        
    }
    
    private var isFirstEdit = true
    func textFieldDidBeginEditing(_ textField: UITextField) {
        button.isUserInteractionEnabled = false

        minLabel.textColor = Colors.text
        textField.textColor = Colors.orange
        
        isFirstEdit = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.pickerViewDidEndEditing?(self)
        button.isUserInteractionEnabled = true
        textField.isUserInteractionEnabled = false

        minLabel.textColor = self.style == .inline ? Colors.orange : Colors.text
        textField.textColor = self.style == .inline ? Colors.orange : Colors.text
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.delegate?.pickerViewDidEdit?(self)
        
        if isFirstEdit {
            if Int(string) == nil { return false }
            
            textField.text = string.isEmpty ? "0" : string
            isFirstEdit = false
            _value = Int(string) ?? 0
            return false
        }
        
        if textField.text == "0" {
            textField.text = string.isEmpty ? "0" : string
            _value = Int(string) ?? 0
            return false
        }
        
        if range.length == -1 {
            if textField.hasText {
                _value = Int(textField.text ?? "0") ?? 0
                return false
            }
            else {
                textField.text = "0"
                _value = 0
                return false
            }
            
        }
        
        if let text = textField.text, let textRange = Range(range, in: text) {
            let updatedText = text.replacingCharacters(in: textRange, with: string)
            
            if updatedText.count > 3 {
                return false
            }
            
            if let number = Int(updatedText) {
                if String(number) == updatedText {
                    _value = number
                    return true
                }
                else {
                    return false
                }
            }
            else if updatedText.isEmpty {
                textField.text = "0"
                _value = 0
                return false
            }
            else {
                return false
            }
            
            
        }
        return true
        
    }
    
    
    
}

class UnselectableTextField: UITextField {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        false
    }

    override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        []
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        .zero
    }
    
    override func deleteBackward() {
        self.delegate?.textField?(self, shouldChangeCharactersIn: NSRange(location: 0, length: -1), replacementString: "")
        super.deleteBackward()
    }
}

class MinuteSuggestionsToolbar: Separator, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private var layout: UICollectionViewFlowLayout!
    private var collectionView: UICollectionView!
    
    private let sizeLabel = UILabel()
    private var data = [5, 15, 30, 45, 60, 90, 120]
    
    public var selectionHandler: ((Int, Bool)->Void)?
    public var useSuggested = false {
        didSet {
            if useSuggested {
                data = [0, 5, 15, 30, 45, 60, 90, 120]
            }
            else {
                data = [5, 15, 30, 45, 60, 90, 120]
            }
            collectionView.reloadData()
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        self.position = .top
        self.color = Colors.barSeparator
        self.backgroundColor = Colors.foregroundColor
        
        self.bounds.size.height = 56
        
        sizeLabel.font = Fonts.medium.withSize(17)
        
        layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 7)
        layout.minimumLineSpacing = 10
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(MinuteSuggestionCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        self.addSubview(collectionView)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        collectionView.frame = self.bounds
        collectionView.setContentOffset(CGPoint(x: -collectionView.contentInset.left, y: 0), animated: false)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if useSuggested, indexPath.row == 0 {
            sizeLabel.text = "Until now"
        }
        else {
            sizeLabel.text = "\(data[indexPath.row]) min"
        }
        
        let size = sizeLabel.sizeThatFits(collectionView.bounds.size).width
        
        return CGSize(width: size + 28, height: 34)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MinuteSuggestionCell
        
        if useSuggested, indexPath.row == 0 {
            cell.suggestedTime = 0
        }
        else {
            cell.suggestedTime = nil
            cell.minutes = data[indexPath.row]
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectionHandler?(data[indexPath.row], useSuggested && indexPath.row == 0)
    }
}

fileprivate class MinuteSuggestionCell: UICollectionViewCell {
    
    private let label = UILabel()
    public var minutes: Int = 0 {
        didSet {
            label.text = "\(minutes) min"
        }
    }
    
    public var suggestedTime: Int? {
        didSet {
            if suggestedTime != nil {
                label.text = "Until now"
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = Colors.lightColor
        self.roundCorners(7)
        
        label.textColor = Colors.text
        label.font = Fonts.medium.withSize(17)
        label.textAlignment = .center
        self.addSubview(label)

    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                label.alpha = 0.2
            }
            else {
                UIView.animate(withDuration: 0.2) {
                    self.label.alpha = 1
                }
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.frame = self.bounds
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

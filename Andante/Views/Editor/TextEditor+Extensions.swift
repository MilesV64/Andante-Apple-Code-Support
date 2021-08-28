//
//  TextEditor+Extensions.swift
//  Andante
//
//  Created by Miles Vinson on 4/4/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

extension UITextView {
    var textRange: NSRange {
        return NSRange(location: 0, length: self.textStorage.length)
    }
}

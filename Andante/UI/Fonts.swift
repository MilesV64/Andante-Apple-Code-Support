//
//  Fonts.swift
//  Andante
//
//  Created by Miles Vinson on 7/14/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import UIKit

class Fonts {
    
    private static let FontAttributes: [UIFontDescriptor.AttributeName : Any] = {
        let settings: [[UIFontDescriptor.FeatureKey: Int]] = [
            [.featureIdentifier: kStylisticAlternativesType, .typeIdentifier: 14]
        ]
        return [.featureSettings: settings]
    }()
    
    private static func Font(_ weight: UIFont.Weight) -> UIFont {
        let font = UIFont.systemFont(ofSize: 17, weight: weight)
        let descriptor = font.fontDescriptor.addingAttributes(Fonts.FontAttributes)
        return UIFont(descriptor: descriptor, size: 0)
    }
    
    static var light: UIFont {
        return Font(.light)
    }
    
    static var regular: UIFont {
        return Font(.regular)
    }
    
    static var medium: UIFont {
        return Font(.medium)
    }
    
    static var semibold: UIFont {
        return Font(.semibold)
    }
    
    static var bold: UIFont {
        return Font(.bold)
    }
    
    static var heavy: UIFont {
        return Font(.heavy)
    }
    
}

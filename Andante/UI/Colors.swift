//
//  Colors.swift
//  Andante
//
//  Created by Miles Vinson on 7/14/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import UIKit

class Colors: NSObject {
    
    class var white: UIColor {
        return Colors.dynamicColor(light: .white, dark: UIColor("#F9FAF9"))
    }
    
    //MARK: - Bars
    class var barColor: UIColor {
        return Colors.dynamicColor(light: .white, dark: Colors.foregroundColor)
    }

    class var barSeparator: UIColor {
        return dynamicColor(light: Colors.text.withAlphaComponent(0.12), dark: UIColor("DEE5FF").withAlphaComponent(0.1))
    }
    
    
    //MARK: - Separator
    
    class var lightSeparatorColor: UIColor {
        return dynamicColor(light: Colors.text.withAlphaComponent(0.08), dark: UIColor("DEE5FF").withAlphaComponent(0.04))
    }
    
    class var separatorColor: UIColor {
        return dynamicColor(light: Colors.text.withAlphaComponent(0.12), dark: UIColor("DEE5FF").withAlphaComponent(0.08))
    }
    
    //MARK: - Light Color
    class var lightColorOpaque: UIColor {
        return Colors.dynamicColor(light: UIColor("#F2F2F7"), dark: UIColor("#282930"))
    }
    
    class var lightColor: UIColor {
        return Colors.dynamicColor(
            light: UIColor("#7575AA").withAlphaComponent(0.1),
            dark: UIColor("#8C90AD").withAlphaComponent(0.1))
    }
    
    class var extraLightColor: UIColor {
        return Colors.dynamicColor(
            light: UIColor("#7575AA").withAlphaComponent(0.06),
            dark: UIColor("#8C90AD").withAlphaComponent(0.06))
    }
    
    //MARK: - Cells
    class var cellHighlightColor: UIColor {
        return Colors.dynamicColor(light: Colors.lightText.withAlphaComponent(0.03), dark: Colors.backgroundColor.toColor(Colors.foregroundColor, percentage: 70))
    }
    
    //MARK: - Background
    class var backgroundColor: UIColor {
        return Colors.dynamicColor(light: UIColor("#F6F5FB"), dark: UIColor("#131314"))
    }
    
    class var foregroundColor: UIColor {
        return Colors.dynamicColor(light: .white, dark: UIColor("#1E1E24"))
    }
    
    class var elevatedForeground: UIColor {
        return Colors.dynamicColor(light: .white, dark: UIColor("#26262E"))
    }
    
    class var flatBackgroundColor: UIColor {
        return Colors.dynamicColor(light: .white, dark: Colors.backgroundColor)
    }
    
    class var lightBackground: UIColor {
        return Colors.dynamicColor(light: UIColor("#627784"), dark: UIColor("#E1E6EA"))
    }
    
    
    //MARK: - Text
    class var text: UIColor {
        return Colors.dynamicColor(light: .black, dark: UIColor("#FEFFFE"))
        return Colors.dynamicColor(light: UIColor("#333539"), dark: UIColor("#FEFFFE"))
    }
    
    class var lightText: UIColor {
        return Colors.dynamicColor(light: UIColor("#1E3458").withAlphaComponent(0.52), dark: UIColor("#8799A5").withAlphaComponent(0.8))
    }
    
    class var extraLightText: UIColor {
        return Colors.dynamicColor(light: UIColor("#0C182C").withAlphaComponent(0.3), dark: UIColor("#8799A5").withAlphaComponent(0.6))
    }
    
    class var lightBlue: UIColor {
        return UIColor("#51AAF2")
        
    }
    
    class var green: UIColor {
        return Colors.dynamicColor(light: UIColor("#6FCF97"), dark: UIColor("#6BD196"))
    }
    
    class var dimColor: UIColor {
        return Colors.dynamicColor(
            light: UIColor.black.withAlphaComponent(0.18),
            dark: UIColor.black.withAlphaComponent(0.32))
    }
    
    class var lighterDimColor: UIColor {
        return Colors.dynamicColor(
            light: UIColor.black.withAlphaComponent(0.1),
            dark: UIColor.black.withAlphaComponent(0.24))
    }
    
    class var evenLighterDimColor: UIColor {
        return Colors.dynamicColor(
            light: UIColor.black.withAlphaComponent(0.04),
            dark: UIColor.black.withAlphaComponent(0.1))
    }
    
    class var moodColor: UIColor {
        return Colors.orange
    }
    
    class var focusColor: UIColor {
        return Colors.greenBlue
    }
    
    class var practiceTimeColor: UIColor {
        return Colors.lightBlue
    }
    
    class var sessionsColor: UIColor {
        return Colors.dynamicColor(light: UIColor("FFA13D"), dark: UIColor("FEB42B"))
    }
    
    
    class var greenBlue: UIColor {
        return dynamicColor(light: UIColor("#15CABA"), dark: UIColor("15CABA"))
    }
    
    class var orange: UIColor {
        return dynamicColor(light: UIColor("#FD7757", displayP3: true), dark: UIColor("#FF7A6F", displayP3: true))
    }
    
    class var barShadowColor: UIColor {
        return Colors.dynamicColor(light: UIColor("#8585D5").withAlphaComponent(0.5), dark: UIColor.black.withAlphaComponent(0.6))
    }
    
    class var darkerBarShadow: UIColor {
        return Colors.dynamicColor(light: UIColor("#3F3F73").withAlphaComponent(0.5), dark: UIColor.black.withAlphaComponent(0.65))
    }
    
    class var purple: UIColor {
        return UIColor("#5E81F4")
    }
    
    class var red: UIColor {
        return UIColor("#FF5555")
    }
    
    class var searchBarColor: UIColor {
        return ProfileImagePushButton.bgColor
    }
    
}

extension Colors {
    static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return dark
                } else {
                    return light
                }
            }
        } else {
            return light
        }
    }
}

extension UIColor {
    
    convenience init(_ hex: String, displayP3: Bool = true) {
        let r, g, b: CGFloat
        let max: CGFloat = 255

        let start = hex.index(hex.startIndex, offsetBy: hex.hasPrefix("#") ? 1 : 0)
        let hexColor = String(hex[start...])
        
        if hexColor.count == 6 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0

            if scanner.scanHexInt64(&hexNumber) {
                r = CGFloat((hexNumber & 0xff0000) >> 16) / max
                g = CGFloat((hexNumber & 0x00ff00) >> 8) / max
                b = CGFloat(hexNumber & 0x0000ff) / max

                if displayP3 {
                    self.init(displayP3Red: r, green: g, blue: b, alpha: 1)
                }
                else {
                    self.init(red: r, green: g, blue: b, alpha: 1)
                }
                
                return
            }
        }
        
        self.init(white: 0, alpha: 1)
    }
    
}

extension UIView {
    
    func setShadow(radius: CGFloat, yOffset: CGFloat, opacity: Float, color: UIColor? = nil) {
        self.layer.shadowColor = (color ?? UIColor.black).cgColor
        self.layer.shadowRadius = radius
        self.layer.shadowOpacity = opacity
        self.layer.shadowOffset = CGSize(width: 0, height: yOffset)
    }
    
}


extension UIColor {
    func toColor(_ color: UIColor, percentage: CGFloat) -> UIColor {
        let percentage = max(min(percentage, 100), 0) / 100
        switch percentage {
        case 0: return self
        case 1: return color
        default:
            var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
            var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
            guard self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1) else { return self }
            guard color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else { return self }

            return UIColor(red: CGFloat(r1 + (r2 - r1) * percentage),
                           green: CGFloat(g1 + (g2 - g1) * percentage),
                           blue: CGFloat(b1 + (b2 - b1) * percentage),
                           alpha: CGFloat(a1 + (a2 - a1) * percentage))
        }
    }
}



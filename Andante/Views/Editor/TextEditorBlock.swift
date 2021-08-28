//
//  TextEditorBlock.swift
//  Andante
//
//  Created by Miles Vinson on 4/4/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class TextEditorBlock {
    enum BlockType: Int {
        case text, attatchment, divider
    }
    
    enum AttatchmentType: Int {
        case image, video, sketch
    }
    
    
    enum TextStyle: Int {
        case body, header, title, bullet, numbered
        
        var attributes: [ NSAttributedString.Key : Any ] {
            switch self {
            case .title:
                return [
                    .font : Fonts.bold.withSize(26),
                    .foregroundColor : Colors.text
                ]
            case .header:
                return [
                    .font : Fonts.semibold.withSize(21),
                    .foregroundColor : Colors.text
                ]
            default:
                return [
                    .font : Fonts.regular.withSize(17),
                    .paragraphStyle : lineSpacing(4),
                    .foregroundColor : Colors.text
                ]
            }
        }
    }
    
}

fileprivate func lineSpacing(_ lineSpacing: CGFloat) -> NSMutableParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.lineSpacing = lineSpacing
    return style
}

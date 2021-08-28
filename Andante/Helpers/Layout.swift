//
//  Layout.swift
//  Andante
//
//  Created by Miles Vinson on 3/13/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class Layout {
    
    enum HorizontalPosition {
        case leading, center, trailing
    }
    
    static func HStack(
        _ views: [UIView],
        centerY: CGFloat = 0,
        spacing: CGFloat = 0,
        margin: CGFloat = 0,
        position: Layout.HorizontalPosition = .leading
    ) {
        guard
            views.count > 0,
            let superview = views.first?.superview
        else { return }
        
        var totalWidth: CGFloat = 0
        views.forEach { view in
            if view.bounds.size == .zero {
                view.sizeToFit()
            }
            totalWidth += view.bounds.size.width
        }
        
        let totalSpacing = spacing * CGFloat(views.count - 1)
        
        var lastMinX: CGFloat
        if position == .leading {
            lastMinX = margin
        }
        else if position == .center {
            lastMinX = superview.bounds.midX - (totalWidth + totalSpacing)/2 - margin
        }
        else {
            lastMinX = superview.bounds.maxX - (totalWidth + totalSpacing + margin*2)
        }
        
        for view in views {
            view.frame = CGRect(
                x: lastMinX,
                y: centerY - view.bounds.size.height/2,
                width: view.bounds.size.width,
                height: view.bounds.size.height)
            
            lastMinX += view.bounds.width + spacing
        }
        
    }
    
}

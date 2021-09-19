//
//  Constants.swift
//  Andante
//
//  Created by Miles Vinson on 7/14/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import UIKit

extension UIView {
    var responsiveMargin: CGFloat {
        return max(Constants.margin, floor(bounds.width * 0.048))
    }
    
    var responsiveSmallMargin: CGFloat {
        return max(Constants.smallMargin, floor(bounds.width * 0.045))
    }
    
    var constrainedWidth: (width: CGFloat, margin: CGFloat) {
        return constrainedWidth(440)
    }
    
    func constrainedBounds(_ maxWidth: CGFloat) -> CGRect {
        let width = min(bounds.width, maxWidth)
        return CGRect(center: bounds.center, size: CGSize(width: width, height: bounds.height))
    }
    
    func constrainedWidth(_ maxWidth: CGFloat) -> (width: CGFloat, margin: CGFloat) {
        let width = min(bounds.width, maxWidth)
        let margin = Constants.margin + (bounds.width - width)/2
        return (width: width, margin: margin)
    }
    
    func constrainedWidth(
        _ maxWidth: CGFloat
    ) -> (width: CGFloat, margin: CGFloat, extraMargin: CGFloat) {
        let width = min(bounds.width, maxWidth)
        let margin = Constants.margin + (bounds.width - width)/2
        return (width: width, margin: margin, extraMargin: margin - Constants.margin)
    }
}

class Constants {
    
    class var margin: CGFloat {
        return 20
    }
    
    class var largeMargin: CGFloat {
        return 60
    }
    
    class var smallMargin: CGFloat {
        return 18
    }
    
    /* Used for card style views */
    class var xsMargin: CGFloat {
        return 14
    }
    
    class var sidebarWidth: CGFloat {
        return 290
    }
    
    class var modalSize: CGSize {
        return CGSize(width: 600, height: 760)
    }
    
    class var sidebarBreakpoint: CGFloat {
        return 600
    }
    
    class var iconBGSize: CGSize {
        return CGSize(38)
    }
    
    class var iconBGCornerRadius: CGFloat {
        return 10
    }
}

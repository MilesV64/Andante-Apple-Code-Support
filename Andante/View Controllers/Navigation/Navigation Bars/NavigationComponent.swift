//
//  NavigationComponent.swift
//  Andante
//
//  Created by Miles Vinson on 11/1/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

protocol NavigationComponentDelegate: class {
    func navigationComponentDidSelect(index: Int)
    func sidebarDidSelectNewFolder()
    func presentingViewController() -> AndanteViewController
    func navigationComponentDidRequestChangeProfile(sourceView: UIView, sourceRect: CGRect, arrowDirection: UIPopoverArrowDirection)
}

class NavigationComponent: UIView {
    
    public weak var delegate: NavigationComponentDelegate?
    public var activeIndex: Int = 0
    
    public func setSelectedTab(_ index: Int) {}
    
    enum Tab {
        case sessions, stats, journal
        
        var icon: UIImage? {
            switch self {
            case .sessions: return UIImage(named: "HomeFill")
            case .stats: return UIImage(named: "StatsFill")
            case .journal: return UIImage(named: "JournalFill")
            }
        }
        
        var string: String {
            switch self {
            case .sessions: return "Home"
            case .stats: return "Stats"
            case .journal: return "Journal"
            }
        }
    }
    
}

//
//  StatIconView.swift
//  Andante
//
//  Created by Miles Vinson on 8/9/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class StatIconView: UIView {
    
    private let imgView = UIImageView()
    private var extraImageView: UIImageView?
    
    public var value: Int? {
        didSet {
            if let value = value {
                
                if stat == .mood {
                    imgView.image = UIImage(named: "mood\(value)")
                    imgView.setImageColor(color: Colors.white)
                }
                else if stat == .focus {
                    if value != 5 {
                        imgView.setImageColor(color: Colors.white.withAlphaComponent(0.35))
                        if value != 0 {
                            extraImageView = UIImageView()
                            extraImageView?.image = UIImage(named: "focus\(value)")
                            extraImageView?.setImageColor(color: Colors.white)
                            self.addSubview(extraImageView!)
                        }
                    }
                }
                
            }
        }
    }
        
    public var stat: Stat = .mood {
        didSet {
            self.backgroundColor = stat.color
            imgView.image = stat.icon
            imgView.setImageColor(color: Colors.white)
            
        }
    }
    
    public var iconSize: CGSize = CGSize(18) {
        didSet {
            setNeedsLayout()
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        self.addSubview(imgView)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imgView.bounds.size = iconSize
        imgView.center = self.bounds.center
        
        extraImageView?.bounds.size = imgView.bounds.size
        extraImageView?.center = imgView.center
        
    }
}

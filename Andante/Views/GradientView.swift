
import UIKit

// MARK: - GradientView

class GradientView: UIView {
        
    override class var layerClass: AnyClass { return CAGradientLayer.self }
    
    var gradientLayer: CAGradientLayer {
        return self.layer as! CAGradientLayer
    }

    var colors: [UIColor] = [] {
        didSet {
            self.updateColors()
        }
    }
    
    var locations: [NSNumber]? = nil {
        didSet {
            self.updateColors()
        }
    }
    
    enum Direction {
        case topToBottom
        case bottomToTop
        case leftToRight
        case rightToLeft
    }
    
    var direction: Direction = .topToBottom {
        didSet {
            self.updateColors()
        }
    }
    
    // MARK: Private Implementation
    
    private func updateColors() {
        let layer = self.layer as! CAGradientLayer

        layer.colors = self.colors.map { $0.cgColor }
        layer.locations = self.locations
        
        switch direction {
            case .topToBottom:
                self.gradientLayer.startPoint = CGPoint(x: 0, y: 0)
                self.gradientLayer.endPoint = CGPoint(x: 0, y: 1)
            case .bottomToTop:
                self.gradientLayer.startPoint = CGPoint(x: 0, y: 1)
                self.gradientLayer.endPoint = CGPoint(x: 0, y: 0)
            case .leftToRight:
                self.gradientLayer.startPoint = CGPoint(x: 0, y: 0)
                self.gradientLayer.endPoint = CGPoint(x: 1, y: 0)
            case .rightToLeft:
                self.gradientLayer.startPoint = CGPoint(x: 1, y: 0)
                self.gradientLayer.endPoint = CGPoint(x: 0, y: 0)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        guard previousTraitCollection?.userInterfaceStyle != self.traitCollection.userInterfaceStyle else { return }
        
        self.updateColors()
    }
}

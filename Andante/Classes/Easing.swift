//
//  Easing.swift
//
//  Created by Manuel Lopes on 03.09.2017.
//
// swiftlint:disable identifier_name
// swiftlint:disable file_length

import Foundation

//expo
//cubic

/// Enum for each type of easing curve.

public enum Curve {
    case cubic
    case exponential

    /// The ease-in version of the curve.
    public var easeIn: (Double) -> Double {
        return EasingMode.easeIn.mode(self)
    }

    // The ease-out version of the curve.
    public var easeOut: (Double) -> Double {
        return EasingMode.easeOut.mode(self)
    }

    /// The ease-in-out version of the curve.
    public var easeInOut: (Double) -> Double {
        return EasingMode.easeInOut.mode(self)
    }
    
    public var linear: (Double) -> Double {
        return { (x) in return x }
    }
    
}

// MARK: - Private

/// Convenience type to return the corresponding easing function for each curve.
private enum EasingMode {
    case easeIn
    case easeOut
    case easeInOut

    func mode ( _ w: Curve) -> (Double) -> Double {
        switch w {
        case .cubic:
            switch self {
            case .easeIn:
                return cubicEaseIn
            case .easeOut:
                return cubicEaseOut
            case .easeInOut:
                return cubicEaseInOut
            }
        case .exponential:
            switch self {
            case .easeIn:
                return exponentialEaseIn
            case .easeOut:
                return exponentialEaseOut
            case .easeInOut:
                return exponentialEaseInOut
            }
        }
    }
}


// MARK: - Cubic

private func cubicEaseIn(_ x: Double) -> Double {
    return x * x * x
}

private func cubicEaseOut(_ x: Double) -> Double {
    let p = x - 1.0
    return  p * p * p + 1.0
}

private func cubicEaseInOut(_ x: Double) -> Double {
    if x < 0.5 {
        return 4.0 * x * x * x
    } else {
        let f = 2.0 * x - 2.0
        return 0.5 * f * f * f + 1.0
    }
}

// MARK: - Exponencial

private func exponentialEaseIn(_ x: Double) -> Double {
    return x == 0.0 ? x : (10.0 * (x - 1.0)).powerOfTwo
}

private func exponentialEaseOut(_ x: Double) -> Double {
    return x == 1.0 ? x : 1.0 - (-10.0 * x).powerOfTwo
}

private func exponentialEaseInOut(_ x: Double) -> Double {
    if x == 0.0 || x == 1.0 {
        return x
    }

    let half: Double = 0.5
    let twenty: Double = 20
    let ten: Double = 10
    
    if x < half {
        return half * (twenty * x - ten).powerOfTwo
    } else {
        let h = (-twenty * x + ten).powerOfTwo
        return -half * h + 1.0
    }
}

extension Double {
    var powerOfTwo: Double {
        return pow(2, self)
    }
}

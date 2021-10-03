
import UIKit

class Helpers {
    class func rectFromCircle(center: CGPoint, radius: CGFloat) -> CGRect {
        let topLeftPoint = CGPoint(x: center.x + radius * CGFloat(cos(self.toRadians(degrees: 135))), y: center.y + radius * CGFloat(sin(toRadians(degrees: 135))))
        let topRightPoint = CGPoint(x: center.x + radius * CGFloat(cos(self.toRadians(degrees: 45))), y: center.y + radius * CGFloat(sin(self.toRadians(degrees: 45))))
        let bottomRightPoint = CGPoint(x: center.x + radius * CGFloat(cos(self.toRadians(degrees: 315))), y: center.y + radius * CGFloat(sin(self.toRadians(degrees: 315))))
        //        let bottomLeftPoint = CGPoint(x: center.x + radius * CGFloat(cos(toRadians(degrees: 225))), y: center.y + radius * CGFloat(sin(toRadians(degrees: 225))))
        
        let width = topRightPoint.x - topLeftPoint.x
        let height = bottomRightPoint.y - topRightPoint.y
        
        return CGRect(x: topLeftPoint.x, y: topLeftPoint.y, width: width, height: height)
    }
    
    class func toRadians(degrees: Int) -> Double{
        return Double(degrees) * Double.pi/180.0
    }
    
    class func distance(_ pt1: CGPoint, _ pt2: CGPoint) -> CGFloat {
        return sqrt(pow(pt2.x - pt1.x, 2) + pow(pt2.y - pt1.y, 2))
    }
    
    class func getDateFromString(dateStr: String) -> Date?
    {
        //Input: "dd/mm/yyyy"
        
        let calendar = Calendar.current
        let dateComponentArray = dateStr.components(separatedBy: "/")
        
        if dateComponentArray.count == 3 {
            var components = DateComponents()
            components.year = Int(dateComponentArray[2])
            components.month = Int(dateComponentArray[1])
            components.day = Int(dateComponentArray[0])
            components.calendar = Calendar.current
            guard let date = calendar.date(from: components) else {
                return nil
            }
            
            return date
        } else {
            return nil
        }
        
    }
    
    
    class func week(of date: Date, mondayStart: Bool) -> [Day]
    {
        var weekStart: Date!
        
        if mondayStart {
            if Calendar.current.component(.weekday, from: date) == 1
            {
                weekStart = date.addingTimeInterval(-24*3600).startOfWeekMonday
                //necessary for this to correctly calculate monday due to how swift orders days of the week
            }
            else
            {
                weekStart = date.startOfWeekMonday
            }
        }
        else {
            weekStart = date.startOfWeekSunday
        }
        
        var days: [Day] = []
        for i in 0...6
        {
            let nextDate = weekStart.addingTimeInterval(24*3600*Double(i))
            days.append(Day(date: nextDate))
        }
        
        return days
    }
    
    /**
     Tests if two dates are in the same week, with a week being defined as Monday through Sunday
     */
    class func areDatesInWeek(date1: Date, date2: Date, mondayStart: Bool) -> Bool
    {
        let day1 = Day(date: date1)
        
        let day2 = Day(date: date2)
        
        let week = Helpers.week(of: date1, mondayStart: mondayStart)
        var day1InWeek = false
        var day2InWeek = false
        
        for day in week
        {
            if day1 == day
            {
                day1InWeek = true
            }
            if day2 == day
            {
                day2InWeek = true
            }
        }
        
        return (day1InWeek && day2InWeek)
    }
    
    class func monthString(from date: Date) -> String
    {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        var text = ""
        switch month
        {
        case 1: text = "JANUARY"
        case 2: text = "FEBRUARY"
        case 3: text = "MARCH"
        case 4: text = "APRIL"
        case 5: text = "MAY"
        case 6: text = "JUNE"
        case 7: text = "JULY"
        case 8: text = "AUGUST"
        case 9: text = "SEPTEMBER"
        case 10: text = "OCTOBER"
        case 11: text = "NOVEMBER"
        case 12: text = "DECEMBER"
        default: text = ""
        }
        
        return text + " " + String(year)
    }
    
}

extension Date {
    func isTheSameDay(as anotherDate: Date) -> Bool {
        let calendar = Calendar.current
        
        return (calendar.component(.year, from: self) == calendar.component(.year, from: anotherDate)
            && calendar.component(.month, from: self) == calendar.component(.month, from: anotherDate)
            && calendar.component(.day, from: self) == calendar.component(.day, from: anotherDate))
    }
    
    /**
     Returns integer value of the day of the week.
     0 = Monday, 6 = Sunday
     */
    func weekday() -> Int {
        
        //restructure to make sunday = 7 (apple default: sun=1), everything else down 1
        //mon = 1 ... sun = 7
        
        var currentDay = Calendar.current.component(.weekday, from: self) - 1
        if currentDay == 0 {
            currentDay = 7
        }
        
        return currentDay-1
    }
    
    func startOfMonth() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
    }
    
    func endOfMonth() -> Date {
        return Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: self.startOfMonth())!
    }
    
}

extension UIView {
    static func animateWithCurve(duration: TimeInterval, delay: TimeInterval = 0, x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat,
                                 animation: (()->Void)?, completion: (()->Void)?) {
        
        let anim = UIViewPropertyAnimator(duration: duration, controlPoint1: CGPoint(x: x1, y: y1), controlPoint2: CGPoint(x: x2, y: y2)) {
            animation?()
        }
                
        anim.addCompletion { (complete) in
            completion?()
        }
        
        anim.startAnimation(afterDelay: delay)
        
    }
}

func easeTranslation(
    _ translation: CGFloat,
    min: CGFloat? = nil,
    max: CGFloat? = nil,
    alpha: CGFloat = 0.015
) -> CGFloat {
    
    if let min = min, translation < min {
        let t = min - translation
        return min - (1 - exp(-alpha*t))/alpha
    }
    else if let max = max, translation > max {
        let t = translation - max
        return max + (1 - exp(-alpha*t))/alpha
    }
    
    return translation
    
}


extension CGRect {
    
    /**
     Creates a CGRect from a start to end point
     - Parameter startPoint: Top left point of the rectangle
     - Parameter endPoint: Bottom right point of the rectangle
     */
    init(from startPoint: CGPoint, to endPoint: CGPoint) {
        self.init(x: startPoint.x, y: startPoint.y,
                  width: endPoint.x - startPoint.x,
                  height: endPoint.y - startPoint.y)
    }
    
    /**
     Creates a CGRect around a center point, with a given size
     - Parameter center: The center of the rectangle
     */
    init(center: CGPoint, size: CGSize) {
        self.init(x: center.x - size.width/2,
                  y: center.y - size.height/2,
                  width: size.width,
                  height: size.height)
    }
}

extension UIView {
    class func FadeTransition(duration: TimeInterval,
                              fadeTimeScale: TimeInterval = 0.4,
                              firstAnimations: @escaping (()->Void),
                              secondAnimations: @escaping (()->Void)) {
                
        let fadeTime = duration * fadeTimeScale
        
        UIView.animate(withDuration: duration/2 + fadeTime/2, delay: 0, options: [.curveEaseIn], animations: firstAnimations, completion: nil)
        
        UIView.animate(withDuration: duration/2 + fadeTime/2, delay: duration/2, options: [.curveEaseOut], animations: secondAnimations, completion: nil)
    }
}

extension UIView {
    /**
     Makes the view have circular edges, or uses a given corner radius.
     If cornerRadius is nil, this needs to be called in layoutSubviews to work
     */
    func roundCorners(_ cornerRadius: CGFloat? = nil, prefersContinuous: Bool = true) {
        if prefersContinuous {
            self.layer.cornerCurve = .continuous
        }
        self.layer.cornerRadius = cornerRadius ?? self.bounds.height/2
    }
    
    /**
     Masks the view to the given corner radius or height/2. Makes a smoother corner effect but cannot be used with shadows. Must be called in layoutSubviews.
     */
    func maskCorners(_ cornerRadius: CGFloat? = nil, corners: UIRectCorner = UIRectCorner.allCorners) {
        let radius = cornerRadius ?? self.bounds.height/2
        
        let mask = CAShapeLayer()
        mask.path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius)).cgPath
        
        self.layer.mask = mask
    }
}

extension UIViewController {
    
    func presentModal(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)?) {
        if #available(iOS 15.0, *) {
            viewControllerToPresent.sheetPresentationController?.preferredCornerRadius = 25
        }
        self.present(viewControllerToPresent, animated: animated, completion: completion)
    }
    
}

extension Date {
    var startOfWeek: Date? {
        let calendar = Calendar.current
        guard let sunday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return calendar.date(byAdding: .day, value: 1, to: sunday)
    }
    
    var startOfWeekSunday: Date {
        let calendar = Calendar.current
        let sunday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))
        return sunday!
    }
    
    var startOfWeekMonday: Date {
        let calendar = Calendar.current
        let sunday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))
        return calendar.date(byAdding: .day, value: 1, to: sunday!)!
    }
    
    var endOfWeek: Date? {
        let gregorian = Calendar(identifier: .gregorian)
        guard let sunday = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return gregorian.date(byAdding: .day, value: 7, to: sunday)
    }
}

extension UIEdgeInsets {
    /**
     Creates Edge Insets with the given inset as all 4 parameters
     */
    init(_ inset: CGFloat) {
        self.init(top: inset, left: inset, bottom: inset, right: inset)
    }
}

extension CGSize {
    /**
     Creates CGSize with the size as both width and height
     */
    init(_ size: CGFloat) {
        self.init(width: size, height: size)
    }
}

func springAnimate(animations: @escaping (()->Void), completion: ((Bool)->Void)? = nil) {
    UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.76, initialSpringVelocity: 0, options: [], animations: {
        
        animations()
        
        
    }, completion: { complete in
        
        completion?(complete)
        
    })
    
}

extension UIImageView {
    func setImageColor(color: UIColor) {
        let templateImage = self.image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        self.image = templateImage
        self.tintColor = color
    }
}

extension Array {
    func insertionIndexOf(elem: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
        var lo = 0
        var hi = self.count - 1
        while lo <= hi {
            let mid = (lo + hi)/2
            if isOrderedBefore(self[mid], elem) {
                lo = mid + 1
            } else if isOrderedBefore(elem, self[mid]) {
                hi = mid - 1
            } else {
                return mid // found at position mid
            }
        }
        return lo // not found, would be inserted at position lo
    }
}

extension UIAlertController {
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.tintColor = Colors.purple
    }
}

extension CGPoint {
    func offset(dx: CGFloat, dy: CGFloat) -> CGPoint {
        return CGPoint(x: self.x + dx, y: self.y + dy)
    }
    
    func offset(by point: CGPoint) -> CGPoint {
        return CGPoint(x: self.x + point.x, y: self.y + point.y)
    }
}

extension NSAttributedString {
    convenience init(string: String?, font: UIFont? = nil, color: UIColor? = nil, lineSpacing: CGFloat? = nil, paragraphSpacing: CGFloat? = nil) {
        
        var attributes: [NSAttributedString.Key : Any] = [:]
        
        if let font = font {
            attributes[.font] = font
        }
        
        if let color = color {
            attributes[.foregroundColor] = color
        }
        
        if lineSpacing != nil || paragraphSpacing != nil {
            let paragraphStyle = NSMutableParagraphStyle()
            
            if let lineSpacing = lineSpacing {
                paragraphStyle.lineSpacing = lineSpacing
            }
            
            if let paragraphSpacing = paragraphSpacing {
                paragraphStyle.paragraphSpacing = paragraphSpacing
            }
            
            attributes[.paragraphStyle] = paragraphStyle
        }
        
        self.init(string: string ?? "", attributes: attributes)        
    }
}



extension UIView {
    /**
     Sets constraints so the view has the same bounds as the superview's frame
     */
    func setConstraintsForSuperviewSize() {
        guard let superview = self.superview else { return }
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: superview.topAnchor),
            self.bottomAnchor.constraint(equalTo: superview.bottomAnchor),
            self.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: superview.trailingAnchor),
        ])
    }
}

func clamp(value: CGFloat, min lowerValue: CGFloat, max higherValue: CGFloat) -> CGFloat {
    return min(higherValue, max(value, lowerValue))
}

func animateCornerRadius(_ view: UIView, from: CGFloat, to: CGFloat) {
    let anim = CABasicAnimation(keyPath: "cornerRadius")
    anim.fromValue = from
    anim.toValue = to
    anim.duration = 0.2
    anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    view.layer.add(anim, forKey: "cornerRadius")
    view.layer.cornerRadius = to
}

extension UIView {
    enum CustomAnimationCurve {
        case exponential, cubic
        
        var easeOut: [CGFloat] {
            switch self {
            case .exponential:
                return [0.16, 1, 0.3, 1]
            case .cubic:
                return [0.33, 1, 0.68, 1]
            }
        }
        var easeInOut: [CGFloat] {
            switch self {
            case .exponential:
                return [0.87, 0, 0.13, 1]
            case .cubic:
                return [0.65, 0, 0.35, 1]
            }
        }
    }
    
    class func animateWithCurve(duration: TimeInterval, delay: TimeInterval = 0, curve: [CGFloat], animation: (()->Void)?, completion: (()->Void)?) {
        
        UIView.animateWithCurve(duration: duration, delay: delay, x1: curve[0], y1: curve[1], x2: curve[2], y2: curve[3], animation: animation, completion: completion)
    }
}

extension UIImage {
    
    convenience init?(name: String, pointSize: CGFloat, weight: UIFont.Weight) {
        
        if #available(iOS 13.0, *) {
            
            var symbolWeight: UIImage.SymbolWeight = .regular
            switch weight {
            case .light:
                symbolWeight = .light
            case .regular:
                symbolWeight = .regular
            case .medium:
                symbolWeight = .medium
            case .semibold:
                symbolWeight = .semibold
            case .bold:
                symbolWeight = .bold
            default:
                symbolWeight = .bold
            }
            
            self.init(
                systemName: name,
                withConfiguration: UIImage.SymbolConfiguration(
                    pointSize: pointSize, weight: symbolWeight))
                
        }
        else {
            self.init(named: name)
        }
        
    }
    
}

extension UIView {
    func addSubviews(_ subviews: [UIView]) {
        subviews.forEach { (view) in
            self.addSubview(view)
        }
    }
}

extension UIView {
    func animateBorderWidth(duration: TimeInterval, to width: CGFloat) {
        let anim = CABasicAnimation(keyPath: "borderWidth")
        anim.fromValue = self.layer.borderWidth
        anim.toValue = width
        anim.duration = duration
        self.layer.add(anim, forKey: "borderWidth")
        self.layer.borderWidth = width
    }
}

extension UIView {
    
    var contextualFrame: CGRect {
        get {
            return CGRect(center: self.center, size: self.bounds.size)
        }
        set {
            self.center = newValue.center
            self.bounds.size = newValue.size
        }
    }
    
}

func isSmallScreen() -> Bool {
    return UIScreen.main.bounds.width < 375
}

extension UIView {
    func setButtonShadow(floating: Bool = false) {
        if floating {
            self.setShadow(radius: 10, yOffset: 5, opacity: 0.1)
        } else {
            self.setShadow(radius: 8, yOffset: 4, opacity: 0.06)
        }
    }
}

public class TransformIgnoringSafeAreaInsetsView: UIView {
    override public var safeAreaInsets: UIEdgeInsets {
        guard let superview = self.superview, superview.transform != .identity else {
            return super.safeAreaInsets
        }
        
        return superview.safeAreaInsets
    }
}

public extension UIDevice {
    
    func deviceCornerRadius() -> CGFloat {
        
        let bottomSafeArea = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
        
        if bottomSafeArea == 0 {
            return 0
        }
        
        let screenSize = UIScreen.main.bounds.size
        let deviceIdiom = UIDevice.current.userInterfaceIdiom
        
        if deviceIdiom == .pad {
            return 18
        }
        else if deviceIdiom == .phone {
            if screenSize.width == 428 {
                return 53.33
            }
            else if screenSize.width == 414 {
                if UIScreen.main.nativeScale == 2 {
                    return 41.5
                } else {
                    return 39
                }
            }
            else if screenSize.width == 390 {
                return 47.33
            }
            else {
                if UIScreen.main.nativeScale == 3 {
                    return 39
                } else {
                    return 44
                }
            }
        }
        
        return 0
        
    }
    
    
}

extension UIEdgeInsets {
    init(t: CGFloat = 0, l: CGFloat = 0, b: CGFloat = 0, r: CGFloat = 0) {
        self.init(top: t, left: l, bottom: b, right: r)
    }
}

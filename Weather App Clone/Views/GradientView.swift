import UIKit

class GradientView: UIView {
    private let gradientLayer = CAGradientLayer()
    
    enum GradientStyle {
        case day
        case night
        case cloudy
        
        var colors: [CGColor] {
            switch self {
            case .day:
                return [
                    UIColor(white: 1, alpha: 0.25).cgColor,
                    UIColor(white: 1, alpha: 0.15).cgColor
                ]
            case .night:
                return [
                    UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 0.25).cgColor,
                    UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 0.15).cgColor
                ]
            case .cloudy:
                return [
                    UIColor(white: 0.9, alpha: 0.25).cgColor,
                    UIColor(white: 0.9, alpha: 0.15).cgColor
                ]
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = 15 // Beautiful rounded corners
        layer.cornerRadius = 15
        layer.masksToBounds = true
        
        // Add a subtle border
        layer.borderWidth = 0.5
        layer.borderColor = UIColor(white: 1, alpha: 0.2).cgColor
    }
    
    private func setupGradient() {
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
        updateStyle(.day) // Default style
    }
    
    func updateStyle(_ style: GradientStyle) {
        gradientLayer.colors = style.colors
    }
} 
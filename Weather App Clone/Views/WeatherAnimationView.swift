import UIKit

class WeatherAnimationView: UIView {
    
    private var emitterLayer: CAEmitterLayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
    }
    
    func startAnimation(for condition: String) {
        stopAnimation()
        
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: bounds.width / 2, y: -50)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: bounds.width, height: 1)
        
        var cells: [CAEmitterCell] = []
        
        switch condition.lowercased() {
        case _ where condition.contains("rain"):
            cells.append(createRainCell())
        case _ where condition.contains("snow"):
            cells.append(createSnowCell())
        case _ where condition.contains("cloud"):
            cells.append(createCloudCell())
        default:
            return
        }
        
        emitter.emitterCells = cells
        layer.addSublayer(emitter)
        emitterLayer = emitter
    }
    
    func stopAnimation() {
        emitterLayer?.removeFromSuperlayer()
        emitterLayer = nil
    }
    
    private func createRainCell() -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = 20
        cell.lifetime = 8.0
        cell.velocity = 200
        cell.velocityRange = 50
        cell.emissionLongitude = .pi
        cell.emissionRange = .pi / 8
        cell.scale = 0.1
        cell.scaleRange = 0.05
        cell.contents = createRainDrop()?.cgImage
        cell.color = UIColor(white: 1, alpha: 0.3).cgColor
        return cell
    }
    
    private func createSnowCell() -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = 10
        cell.lifetime = 20.0
        cell.velocity = 50
        cell.velocityRange = 20
        cell.emissionLongitude = .pi
        cell.emissionRange = .pi / 8
        cell.spin = 1
        cell.spinRange = 1
        cell.scale = 0.5
        cell.scaleRange = 0.25
        cell.contents = UIImage(systemName: "snow")?.cgImage
        cell.color = UIColor(white: 1, alpha: 0.8).cgColor
        return cell
    }
    
    private func createCloudCell() -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = 0.2
        cell.lifetime = 20.0
        cell.velocity = 10
        cell.velocityRange = 5
        cell.emissionLongitude = 0
        cell.scale = 0.8
        cell.scaleRange = 0.2
        cell.contents = UIImage(systemName: "cloud.fill")?.cgImage
        cell.color = UIColor(white: 1, alpha: 0.3).cgColor
        return cell
    }
    
    private func createRainDrop() -> UIImage? {
        let size = CGSize(width: 4, height: 8)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
} 
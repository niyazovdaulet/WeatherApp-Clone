import UIKit

class HourlyWeatherCell: UICollectionViewCell {
    static let identifier = "HourlyWeatherCell"
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.font = .systemFont(ofSize: 15, weight: .medium)
        return label
    }()
    
    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        return label
    }()
    
    private let weatherIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        [timeLabel, weatherIconImageView, temperatureLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            timeLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            weatherIconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            weatherIconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            weatherIconImageView.widthAnchor.constraint(equalToConstant: 30),
            weatherIconImageView.heightAnchor.constraint(equalToConstant: 30),
            
            temperatureLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            temperatureLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
    
    func configure(with hourly: Hourly) {
        // Convert timestamp to hour
        let date = Date(timeIntervalSince1970: TimeInterval(hourly.dt))
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        timeLabel.text = formatter.string(from: date).lowercased()
        
        // Set temperature
        temperatureLabel.text = "\(Int(round(hourly.temp)))°"
        
        // Set weather icon
        if let condition = hourly.weather.first?.main.lowercased() {
            var iconName = ""
            switch condition {
            case _ where condition.contains("clear"):
                iconName = "sun.max.fill"
            case _ where condition.contains("cloud"):
                iconName = "cloud.fill"
            case _ where condition.contains("rain"):
                iconName = "cloud.rain.fill"
            case _ where condition.contains("snow"):
                iconName = "snow"
            case _ where condition.contains("thunderstorm"):
                iconName = "cloud.bolt.fill"
            default:
                iconName = "cloud.fill"
            }
            weatherIconImageView.image = UIImage(systemName: iconName)
        }
    }
} 
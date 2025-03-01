import UIKit

class DailyWeatherCell: UITableViewCell {
    static let identifier = "DailyWeatherCell"
    
    private let dayLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let weatherIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    private let highTempLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .right
        return label
    }()
    
    private let lowTempLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white.withAlphaComponent(0.7)
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .right
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none
        
        [dayLabel, weatherIconImageView, highTempLabel, lowTempLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            dayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dayLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            weatherIconImageView.leadingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -15),
            weatherIconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            weatherIconImageView.widthAnchor.constraint(equalToConstant: 30),
            weatherIconImageView.heightAnchor.constraint(equalToConstant: 30),
            
            highTempLabel.trailingAnchor.constraint(equalTo: lowTempLabel.leadingAnchor, constant: -16),
            highTempLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            highTempLabel.widthAnchor.constraint(equalToConstant: 40),
            
            lowTempLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            lowTempLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            lowTempLabel.widthAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func configure(with daily: Daily) {
        // Set day of week
        let date = Date(timeIntervalSince1970: TimeInterval(daily.dt))
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        dayLabel.text = formatter.string(from: date)
        
        // Set temperatures
        highTempLabel.text = "\(Int(round(daily.temp.max)))°"
        lowTempLabel.text = "\(Int(round(daily.temp.min)))°"
        
        // Set weather icon
        if let condition = daily.weather.first?.main.lowercased() {
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
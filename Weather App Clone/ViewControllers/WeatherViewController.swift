import UIKit
import CoreLocation

class WeatherViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var highLowLabel: UILabel!
    @IBOutlet weak var hourlyCollectionView: UICollectionView!
    @IBOutlet weak var dailyTableView: UITableView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var forecastLabel: UILabel!
    @IBOutlet weak var feelsLikeLabel: UILabel!
    @IBOutlet weak var feelsLikeDescription: UILabel!
    
    // MARK: - Properties
    private var weatherData: WeatherResponse?
    private var currentLocation: CLLocation?
    private let weatherService = WeatherService.shared
    private let locationManager = LocationManager.shared
    private var weatherAnimationView: WeatherAnimationView!
    private var searchTimer: Timer?
    private var hourlyGradientView: GradientView!
    private var dailyGradientView: GradientView!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        setupTableView()
        setupLocationManager()
        setupWeatherAnimationView()
        setupSearchBar()
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Configure UI elements
        cityLabel.textColor = .white
        temperatureLabel.textColor = .white
        conditionLabel.textColor = .white
        highLowLabel.textColor = .white
        forecastLabel.textColor = .white
        forecastLabel.text = "5-DAY FORECAST"
        forecastLabel.font = .systemFont(ofSize: 16, weight: .medium)
        
        // Configure location button
        locationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        locationButton.tintColor = .white
        locationButton.addTarget(self, action: #selector(locationButtonTapped), for: .touchUpInside)
        
        // Add blur effect to background
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundImageView.addSubview(blurEffectView)
        blurEffectView.alpha = 0.5
        
        // Setup gradient views
        setupGradientViews()
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Search for a city"
        searchBar.searchBarStyle = .minimal
        searchBar.barStyle = .black
        searchBar.tintColor = .white
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = .white
            textField.attributedPlaceholder = NSAttributedString(
                string: "Search for a city",
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.6)]
            )
        }
    }
    
    private func setupWeatherAnimationView() {
        weatherAnimationView = WeatherAnimationView(frame: view.bounds)
        weatherAnimationView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(weatherAnimationView, aboveSubview: backgroundImageView)
    }
    
    private func setupCollectionView() {
        hourlyCollectionView.delegate = self
        hourlyCollectionView.dataSource = self
        hourlyCollectionView.register(HourlyWeatherCell.self, forCellWithReuseIdentifier: HourlyWeatherCell.identifier)
        
        // Configure collection view layout
        if let layout = hourlyCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.itemSize = CGSize(width: 60, height: 100)
            layout.minimumInteritemSpacing = 10
            layout.minimumLineSpacing = 10
            // Remove section insets as we'll handle spacing with constraints
            layout.sectionInset = .zero
        }
        
        hourlyCollectionView.showsHorizontalScrollIndicator = false
        hourlyCollectionView.backgroundColor = .clear
        
        // Update hourly collection view constraints to match daily gradient view
        hourlyCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hourlyCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            hourlyCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupTableView() {
        dailyTableView.delegate = self
        dailyTableView.dataSource = self
        dailyTableView.register(DailyWeatherCell.self, forCellReuseIdentifier: DailyWeatherCell.identifier)
        
        dailyTableView.backgroundColor = .clear
        dailyTableView.separatorStyle = .none
        dailyTableView.showsVerticalScrollIndicator = false
        dailyTableView.rowHeight = 50
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestLocationPermission()
    }
    
    private func setupGradientViews() {
        // Setup hourly collection view gradient
        hourlyGradientView = GradientView(frame: hourlyCollectionView.bounds)
        hourlyGradientView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hourlyCollectionView.backgroundView = hourlyGradientView
        
        // Setup daily table view container
        let dailyContainer = UIView(frame: .zero)
        dailyContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dailyContainer)
        
        // Setup daily gradient view
        dailyGradientView = GradientView(frame: .zero)
        dailyGradientView.translatesAutoresizingMaskIntoConstraints = false
        dailyContainer.addSubview(dailyGradientView)
        
        // Move forecast label inside gradient view
        forecastLabel.removeFromSuperview()
        dailyGradientView.addSubview(forecastLabel)
        
        // Setup stack view for daily content
        let dailyStackView = UIStackView()
        dailyStackView.axis = .vertical
        dailyStackView.spacing = 10
        dailyStackView.translatesAutoresizingMaskIntoConstraints = false
        dailyGradientView.addSubview(dailyStackView)
        
        // Move table view to stack view
        dailyTableView.removeFromSuperview()
        dailyStackView.addArrangedSubview(dailyTableView)
        
        // Move feels like container to stack view
        let feelsLikeStack = UIStackView()
        feelsLikeStack.axis = .vertical
        feelsLikeStack.spacing = 4
        feelsLikeStack.translatesAutoresizingMaskIntoConstraints = false
        
        feelsLikeLabel.removeFromSuperview()
        feelsLikeDescription.removeFromSuperview()
        feelsLikeStack.addArrangedSubview(feelsLikeLabel)
        feelsLikeStack.addArrangedSubview(feelsLikeDescription)
        
        dailyStackView.addArrangedSubview(feelsLikeStack)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Daily container constraints
            dailyContainer.topAnchor.constraint(equalTo: hourlyCollectionView.bottomAnchor, constant: 20),
            dailyContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dailyContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            dailyContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // Gradient view constraints
            dailyGradientView.topAnchor.constraint(equalTo: dailyContainer.topAnchor),
            dailyGradientView.leadingAnchor.constraint(equalTo: dailyContainer.leadingAnchor),
            dailyGradientView.trailingAnchor.constraint(equalTo: dailyContainer.trailingAnchor),
            dailyGradientView.bottomAnchor.constraint(equalTo: dailyContainer.bottomAnchor),
            
            // Forecast label constraints
            forecastLabel.topAnchor.constraint(equalTo: dailyGradientView.topAnchor, constant: 16),
            forecastLabel.leadingAnchor.constraint(equalTo: dailyGradientView.leadingAnchor, constant: 16),
            forecastLabel.trailingAnchor.constraint(equalTo: dailyGradientView.trailingAnchor, constant: -16),
            
            // Daily stack view constraints
            dailyStackView.topAnchor.constraint(equalTo: forecastLabel.bottomAnchor, constant: 10),
            dailyStackView.leadingAnchor.constraint(equalTo: dailyGradientView.leadingAnchor),
            dailyStackView.trailingAnchor.constraint(equalTo: dailyGradientView.trailingAnchor),
            dailyStackView.bottomAnchor.constraint(equalTo: dailyGradientView.bottomAnchor, constant: -16),
            
            // Feels like stack padding
            feelsLikeStack.leadingAnchor.constraint(equalTo: dailyStackView.leadingAnchor, constant: 16),
            feelsLikeStack.trailingAnchor.constraint(equalTo: dailyStackView.trailingAnchor, constant: -16)
        ])
        
        // Update table view properties
        dailyTableView.backgroundColor = .clear
        dailyTableView.isScrollEnabled = false // Since it's in a stack view
        
        // Make sure labels don't use autoresizing masks
        forecastLabel.translatesAutoresizingMaskIntoConstraints = false
        feelsLikeLabel.translatesAutoresizingMaskIntoConstraints = false
        feelsLikeDescription.translatesAutoresizingMaskIntoConstraints = false
    }
    
    // MARK: - Actions
    @objc private func locationButtonTapped() {
        // Show loading indicator
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = .white
        activityIndicator.center = locationButton.center
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        locationButton.isHidden = true
        
        // Request location
        locationManager.requestLocationPermission()
        locationManager.startUpdatingLocation()
        
        // Set a timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            activityIndicator.removeFromSuperview()
            self?.locationButton.isHidden = false
            
            if self?.currentLocation == nil {
                self?.showAlert(title: "Location Error",
                             message: "Unable to get your current location. Please check your location settings and try again.")
            }
        }
    }
    
    // MARK: - Data Loading
    private func loadWeatherData(for location: CLLocation) {
        Task {
            do {
                let weather = try await weatherService.fetchWeather(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                await MainActor.run {
                    self.weatherData = weather
                    self.updateUI()
                    self.hourlyCollectionView.reloadData()
                    self.dailyTableView.reloadData()
                }
            } catch WeatherError.invalidAPIKey {
                await MainActor.run {
                    showAlert(title: "API Key Error",
                            message: "The API key is invalid or has expired. Please update the API key in WeatherService.swift")
                }
            } catch WeatherError.apiError(let message) {
                await MainActor.run {
                    showAlert(title: "API Error",
                            message: message)
                }
            } catch {
                await MainActor.run {
                    showAlert(title: "Error",
                            message: "Failed to fetch weather data. Please try again later.")
                }
                print("Error fetching weather: \(error)")
            }
        }
    }
    
    private func searchCity(_ query: String) {
        Task {
            do {
                let cities = try await weatherService.searchCity(query: query)
                if let city = cities.first {
                    let location = CLLocation(latitude: city.lat, longitude: city.lon)
                    await MainActor.run {
                        self.currentLocation = location
                        self.loadWeatherData(for: location)
                    }
                }
            } catch {
                print("Error searching city: \(error)")
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                    message: message,
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - UI Updates
    private func updateUI() {
        guard let weather = weatherData else { return }
        
        temperatureLabel.text = "\(Int(round(weather.current.temp)))°"
        conditionLabel.text = weather.current.weather.first?.description.capitalized
        
        // Update high/low temperature
        if let daily = weather.daily.first {
            highLowLabel.text = "H:\(Int(round(daily.temp.max)))° L:\(Int(round(daily.temp.min)))°"
        }
        
        // Update feels like temperature and description
        let feelsLike = Int(round(weather.current.feels_like))
        let actualTemp = Int(round(weather.current.temp))
        feelsLikeLabel.text = "FEELS LIKE \(feelsLike)°"
        
        // Generate feels like description based on temperature difference
        let tempDiff = feelsLike - actualTemp
        let windSpeed = weather.current.wind_speed
        let humidity = weather.current.humidity
        
        if abs(tempDiff) <= 2 {
            feelsLikeDescription.text = "Similar to the actual temperature"
        } else if tempDiff > 2 {
            if humidity > 70 {
                feelsLikeDescription.text = "Humidity is making it feel warmer"
            } else {
                feelsLikeDescription.text = "Direct sunlight is making it feel warmer"
            }
        } else {
            if windSpeed > 5.5 { // More than 12mph
                feelsLikeDescription.text = "Wind is making it feel colder"
            } else {
                feelsLikeDescription.text = "Shade is making it feel cooler"
            }
        }
        
        // Get city name from coordinates
        let location = CLLocation(latitude: weather.lat, longitude: weather.lon)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self,
                  let placemark = placemarks?.first else { return }
            
            DispatchQueue.main.async {
                if let city = placemark.locality {
                    self.cityLabel.text = city
                }
            }
        }
        
        // Update background and animations based on weather condition
        if let condition = weather.current.weather.first?.main {
            updateBackground(weather: weather)
            weatherAnimationView.startAnimation(for: condition)
        }
        
        // Update gradients based on weather condition
        updateGradients(weather: weather)
    }
    
    private func updateBackground(weather: WeatherResponse) {
        let current = weather.current
        let isNight = Date(timeIntervalSince1970: TimeInterval(current.dt)) > Date(timeIntervalSince1970: TimeInterval(current.sunset))
        
        if let condition = current.weather.first?.main.lowercased() {
            var imageName = ""
            
            switch condition {
            case _ where condition.contains("clear"):
                imageName = isNight ? "night-clear" : "day-clear"
                weatherAnimationView.stopAnimation()
            case _ where condition.contains("rain"):
                imageName = "rain"
            case _ where condition.contains("cloud"):
                imageName = isNight ? "night-cloudy" : "day-cloudy"
            case _ where condition.contains("snow"):
                imageName = "snow"
            default:
                imageName = isNight ? "night-clear" : "day-clear"
                weatherAnimationView.stopAnimation()
            }
            
            UIView.transition(with: backgroundImageView,
                            duration: 0.5,
                            options: .transitionCrossDissolve,
                            animations: { [weak self] in
                self?.backgroundImageView.image = UIImage(named: imageName)
            })
        }
    }
    
    private func updateGradients(weather: WeatherResponse) {
        let current = weather.current
        let isNight = Date(timeIntervalSince1970: TimeInterval(current.dt)) > Date(timeIntervalSince1970: TimeInterval(current.sunset))
        
        let style: GradientView.GradientStyle
        
        if let condition = current.weather.first?.main.lowercased() {
            if condition.contains("cloud") {
                style = .cloudy
            } else if isNight {
                style = .night
            } else {
                style = .day
            }
            
            hourlyGradientView.updateStyle(style)
            dailyGradientView.updateStyle(style)
        }
    }
}

// MARK: - UICollectionViewDelegate & DataSource
extension WeatherViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(weatherData?.hourly.count ?? 0, 24) // Show next 24 hours
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HourlyWeatherCell.identifier, for: indexPath) as? HourlyWeatherCell,
              let hourly = weatherData?.hourly[indexPath.item] else {
            return UICollectionViewCell()
        }
        
        cell.configure(with: hourly)
        return cell
    }
}

// MARK: - UITableViewDelegate & DataSource
extension WeatherViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return min(weatherData?.daily.count ?? 0, 7) // Show 7 days
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DailyWeatherCell.identifier, for: indexPath) as? DailyWeatherCell,
              let daily = weatherData?.daily[indexPath.row] else {
            return UITableViewCell()
        }
        
        cell.configure(with: daily)
        return cell
    }
}

// MARK: - LocationManagerDelegate
extension WeatherViewController: LocationManagerDelegate {
    func locationManager(_ manager: LocationManager, didUpdateLocation location: CLLocation) {
        currentLocation = location
        loadWeatherData(for: location)
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: LocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
        showAlert(title: "Location Error",
                message: "Unable to get your location. Please check your location settings and try again.")
    }
}

// MARK: - UISearchBarDelegate
extension WeatherViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Remove the auto-search functionality
        // We'll only search when the user presses the search button
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        if let searchText = searchBar.text?.trimmingCharacters(in: .whitespaces), !searchText.isEmpty {
            searchCity(searchText)
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // Show the cancel button when search begins
        searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Clear the search bar and hide cancel button when cancel is tapped
        searchBar.text = ""
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
    }
} 

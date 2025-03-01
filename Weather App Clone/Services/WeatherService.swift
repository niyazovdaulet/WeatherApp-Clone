import Foundation
import CoreLocation

enum WeatherError: Error {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case invalidAPIKey
    case apiError(String)
}

struct APIErrorResponse: Codable {
    let cod: Int
    let message: String
}

class WeatherService {
    private let apiKey = "6cc7ba6d5b7f0f9766cb1d21728d9374"
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    
    static let shared = WeatherService()
    
    private init() {}
    
    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherResponse {
        // First, fetch current weather
        let currentWeatherURL = "\(baseURL)/weather?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric"
        
        guard let currentURL = URL(string: currentWeatherURL) else {
            throw WeatherError.invalidURL
        }
        
        // Then, fetch 5-day forecast
        let forecastURL = "\(baseURL)/forecast?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric"
        
        guard let forecastURL = URL(string: forecastURL) else {
            throw WeatherError.invalidURL
        }
        
        do {
            // Create async tasks for both requests
            let currentTask = Task { () -> (Data, URLResponse) in
                try await URLSession.shared.data(from: currentURL)
            }
            
            let forecastTask = Task { () -> (Data, URLResponse) in
                try await URLSession.shared.data(from: forecastURL)
            }
            
            // Wait for both tasks to complete
            let (current, currentResponse) = try await currentTask.value
            let (forecast, forecastResponse) = try await forecastTask.value
            
            // For debugging
            if let currentString = String(data: current, encoding: .utf8) {
                print("Current Weather API Response: \(currentString)")
            }
            if let forecastString = String(data: forecast, encoding: .utf8) {
                print("Forecast API Response: \(forecastString)")
            }
            
            // Check responses for errors
            if let httpResponse = currentResponse as? HTTPURLResponse {
                try checkResponse(httpResponse, data: current)
            }
            if let httpResponse = forecastResponse as? HTTPURLResponse {
                try checkResponse(httpResponse, data: forecast)
            }
            
            // Decode both responses
            let decoder = JSONDecoder()
            let currentWeather = try decoder.decode(CurrentWeatherResponse.self, from: current)
            let forecastWeather = try decoder.decode(ForecastResponse.self, from: forecast)
            
            // Combine into our WeatherResponse format
            return WeatherResponse(
                current: Current(from: currentWeather),
                hourly: createHourlyForecast(from: forecastWeather),
                daily: createDailyForecast(from: forecastWeather),
                lat: latitude,
                lon: longitude,
                timezone: currentWeather.name,
                timezone_offset: 0
            )
            
        } catch let error as DecodingError {
            print("Decoding error: \(error)")
            throw WeatherError.decodingError
        } catch {
            throw WeatherError.networkError(error)
        }
    }
    
    private func checkResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 401:
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw WeatherError.apiError(errorResponse.message)
            }
            throw WeatherError.invalidAPIKey
        case 400...499:
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw WeatherError.apiError(errorResponse.message)
            }
            throw WeatherError.apiError("Client error: \(response.statusCode)")
        case 500...599:
            throw WeatherError.apiError("Server error: \(response.statusCode)")
        default:
            break
        }
    }
    
    private func createHourlyForecast(from forecast: ForecastResponse) -> [Hourly] {
        return forecast.list.prefix(24).map { item in
            Hourly(
                dt: item.dt,
                temp: item.main.temp,
                feels_like: item.main.feels_like,
                pressure: item.main.pressure,
                humidity: item.main.humidity,
                dew_point: 0, // Not available in free API
                uvi: 0, // Not available in free API
                clouds: item.clouds.all,
                visibility: item.visibility ?? 0,
                wind_speed: item.wind.speed,
                wind_deg: item.wind.deg,
                wind_gust: item.wind.gust,
                weather: item.weather,
                pop: item.pop ?? 0
            )
        }
    }
    
    private func createDailyForecast(from forecast: ForecastResponse) -> [Daily] {
        // Group forecast items by day
        let calendar = Calendar.current
        var dailyForecasts: [Date: [ForecastItem]] = [:]
        
        for item in forecast.list {
            let date = Date(timeIntervalSince1970: TimeInterval(item.dt))
            let day = calendar.startOfDay(for: date)
            if dailyForecasts[day] == nil {
                dailyForecasts[day] = []
            }
            dailyForecasts[day]?.append(item)
        }
        
        // Convert grouped forecasts to Daily objects
        return dailyForecasts.sorted { $0.key < $1.key }.prefix(7).map { date, items in
            let temps = items.map { $0.main.temp }
            let minTemp = temps.min() ?? 0
            let maxTemp = temps.max() ?? 0
            
            return Daily(
                dt: Int(date.timeIntervalSince1970),
                sunrise: 0, // Not available in free API
                sunset: 0, // Not available in free API
                moonrise: 0, // Not available in free API
                moonset: 0, // Not available in free API
                moon_phase: 0, // Not available in free API
                temp: Temperature(
                    day: temps.reduce(0, +) / Double(temps.count),
                    min: minTemp,
                    max: maxTemp,
                    night: minTemp,
                    eve: maxTemp,
                    morn: minTemp
                ),
                feels_like: FeelsLike(
                    day: items.first?.main.feels_like ?? 0,
                    night: items.last?.main.feels_like ?? 0,
                    eve: items.last?.main.feels_like ?? 0,
                    morn: items.first?.main.feels_like ?? 0
                ),
                pressure: items.first?.main.pressure ?? 0,
                humidity: items.first?.main.humidity ?? 0,
                dew_point: 0, // Not available in free API
                wind_speed: items.first?.wind.speed ?? 0,
                wind_deg: items.first?.wind.deg ?? 0,
                wind_gust: items.first?.wind.gust,
                weather: items.first?.weather ?? [],
                clouds: items.first?.clouds.all ?? 0,
                pop: items.first?.pop ?? 0,
                uvi: 0, // Not available in free API
                rain: nil,
                snow: nil
            )
        }
    }
    
    func searchCity(query: String) async throws -> [City] {
        let urlString = "https://api.openweathermap.org/geo/1.0/direct?q=\(query)&limit=5&appid=\(apiKey)"
        
        guard let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedString) else {
            throw WeatherError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                try checkResponse(httpResponse, data: data)
            }
            
            let decoder = JSONDecoder()
            return try decoder.decode([City].self, from: data)
        } catch {
            throw WeatherError.networkError(error)
        }
    }
}

// MARK: - Free API Response Models
struct CurrentWeatherResponse: Codable {
    let weather: [Weather]
    let main: MainWeather
    let wind: Wind
    let clouds: Clouds
    let dt: Int
    let sys: Sys
    let name: String
    let visibility: Int
}

struct ForecastResponse: Codable {
    let list: [ForecastItem]
}

struct ForecastItem: Codable {
    let dt: Int
    let main: MainWeather
    let weather: [Weather]
    let clouds: Clouds
    let wind: Wind
    let visibility: Int?
    let pop: Double?
}

struct MainWeather: Codable {
    let temp: Double
    let feels_like: Double
    let temp_min: Double
    let temp_max: Double
    let pressure: Int
    let humidity: Int
}

struct Wind: Codable {
    let speed: Double
    let deg: Int
    let gust: Double?
}

struct Clouds: Codable {
    let all: Int
}

struct Sys: Codable {
    let sunrise: Int?
    let sunset: Int?
}

// MARK: - Conversion Extensions
extension Current {
    init(from response: CurrentWeatherResponse) {
        self.dt = response.dt
        self.sunrise = response.sys.sunrise ?? 0
        self.sunset = response.sys.sunset ?? 0
        self.temp = response.main.temp
        self.feels_like = response.main.feels_like
        self.pressure = response.main.pressure
        self.humidity = response.main.humidity
        self.dew_point = 0 // Not available in free API
        self.uvi = 0 // Not available in free API
        self.clouds = response.clouds.all
        self.visibility = response.visibility
        self.wind_speed = response.wind.speed
        self.wind_deg = response.wind.deg
        self.weather = response.weather
    }
} 

# iPhone Weather App Clone

A clone of the native iOS Weather app built using UIKit and Storyboard. This app uses the OpenWeather API to fetch real-time weather data and provides a native-like experience with animations and background updates.

## Features

- Real-time weather data using OpenWeather API
- Current weather conditions with temperature and description
- Hourly forecast for the next 24 hours
- 7-day weather forecast
- Location-based weather updates
- Background location updates
- Weather animations (rain, snow, clouds)
- Support for both light and dark mode
- Dynamic weather backgrounds based on conditions and time of day

## Requirements

- iOS 18.0+
- Xcode 14.0+
- OpenWeather API Key

## Installation

1. Clone the repository
2. Open the project in Xcode
3. Add your OpenWeather API key in `WeatherService.swift`
4. Build and run the project

## Configuration

The app requires the following permissions:
- Location Services (Always and When In Use)
- Background Location Updates

These permissions are already configured in the Info.plist file.

## Weather Animations

The app includes animated weather effects for:
- Rain
- Snow
- Clouds
- Clear sky (day/night)

## Architecture

The app follows a simple MVC architecture:
- Models: Weather data models and API response structures
- Views: Custom cells for hourly and daily forecasts
- Controllers: Main weather view controller
- Services: Weather API and location services

## Credits

- Weather data provided by [OpenWeather](https://openweathermap.org/)
- Weather icons from SF Symbols
- Background images from Pexels


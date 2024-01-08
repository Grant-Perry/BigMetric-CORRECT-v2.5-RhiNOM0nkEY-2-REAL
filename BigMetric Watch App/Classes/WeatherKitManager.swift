//
//  WeatherKitManager.swift
//  howFar Watch App
//
//  Created by Grant Perry on 4/16/23.
//

import SwiftUI
import WeatherKit
import CoreLocation
import Combine

class WeatherKitManager: NSObject, ObservableObject {
    @ObservedObject var distanceTracker: DistanceTracker 	= DistanceTracker()
    @ObservedObject var geoCodeHelper: GeoCodeHelper 			= GeoCodeHelper()

	var dailyForecast		: Forecast<DayWeather>?
	var hourlyForecast	: Forecast<HourWeather>?
	let weatherService 								= WeatherService()
    let sharedService 								= WeatherService.shared
    var date: Date									= .now
    var latitude: Double							= 0
    var longitude: Double							= 0
	@Published var windSpeedVar: Double			= 0
	@Published var precipForecast: Double		= 0
	@Published var precipForecast2: Double		= 0
	@Published var precipForecastAmount: Double	= 0
	@Published var isErrorAlert: Bool			= false
	@Published var symbolVar: String			= "xmark"
	@Published var tempVar: String				= ""
	@Published var tempHour: String				= ""
   @Published var windDirectionVar: String	= ""
   @Published var highTempVar: String			= ""
   @Published var lowTempVar: String			= ""
   @Published var locationName: String			= ""
   @Published var weekForecast: [Forecasts]	= []
	@Published var symbolHourly: String			= ""
    var cLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    // main method to retrieve the currentForecast and hourlyForecast
    func getWeather(for coordinate: CLLocationCoordinate2D) {
        Task {
            do {
                let weather = try await fetchWeather(for: coordinate)
                let current = weather.currentWeather
                let hourly  = weather.hourlyForecast.first
                guard let dailyForecast = await dailyForecast(for: coordinate) else {
                    print("Failed to fetch daily forecast. [getWeather]")
                    return
                }
                guard let firstHourlyForecast = hourly else { // } hourlyForecast.first else {
                    print("firstHourlyForecast not available.  [getWeather]\n")
                    // Show an error message or take appropriate action
                    return
                }
                
                precipForecast2	= firstHourlyForecast.precipitationChance
                precipForecast	= firstHourlyForecast.precipitationAmount.value
                symbolHourly		= firstHourlyForecast.symbolName
                tempHour			= String(format: "%.0f", firstHourlyForecast.temperature.converted(to: .fahrenheit).value )
                tempVar				= String(format: "%.0f", current.temperature.converted(to: .fahrenheit).value )
                highTempVar		= String(format: "%.0f", dailyForecast.first?.highTemperature.converted(to: .fahrenheit).value ?? 0 )
                lowTempVar			= String(format: "%.0f", dailyForecast.first?.lowTemperature.converted(to: .fahrenheit).value ?? 0 )
                windSpeedVar		= current.wind.speed.converted(to: .milesPerHour).value
                windDirectionVar	= CardinalDirection(course: current.wind.direction.converted(to: .degrees).value).rawValue
                symbolVar			= current.symbolName
                locationName		= distanceTracker.locationName
                
                // Check to see if the dailyForecast array has anything in it for the 10-day forecast; if not, return
                if dailyForecast.isEmpty {
                    return
                }
                
                let howManyDays = min(dailyForecast.count, 10)
                
                // iterate and build the daily weather display
                weekForecast = (0..<howManyDays).map { index in
                    let dailyWeather	= dailyForecast[index]
                    let symbolName		= dailyWeather.symbolName
                    let minTemp			= String(format: "%.0f", dailyWeather.lowTemperature.converted(to: .fahrenheit).value)
                    let maxTemp			= String(format: "%.0f", dailyWeather.highTemperature.converted(to: .fahrenheit).value)
                    return Forecasts(symbolName: symbolName, minTemp: minTemp, maxTemp: maxTemp)
                }
            } catch {
                if let error = error as? URLError, error.code == .notConnectedToInternet {
                    print("Network error: The Internet connection appears to be offline.")
                    isErrorAlert = true
                } else {
                    print("\(error.localizedDescription) - [getWeather]")
                    // Handle other error scenarios or log the error
                }
            }
        }
    }
    
    @discardableResult
    private func fetchWeather(for coordinate: CLLocationCoordinate2D) async throws -> Weather {
        let weather = try await Task.detached(priority: .userInitiated) { [self] in
            return try await self.sharedService.weather(for: self.convertCLL(coordinate))
        }.value
        return weather
    }
    
    @discardableResult
    func dailyForecast(for coordinate: CLLocationCoordinate2D) async -> Forecast<DayWeather>? {
        let currentCoord     	= CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let dayWeather       	= await Task.detached(priority: .userInitiated) {
            let dayForecast	= try? await self.sharedService.weather(
                for: currentCoord,
                including: .daily)
            return dayForecast
        }.value
        print("dayWeather = \(dayWeather?.count ?? 0)")
        return dayWeather
    }
    
    @discardableResult
    func hourlyForecast(for coordinate: CLLocationCoordinate2D) async -> Forecast<HourWeather>? {
        let currentCoord		=  CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let hourWeather			= await Task.detached(priority: .userInitiated) {
            let hourForecast	= try? await self.sharedService.weather(
                for: currentCoord,
                including: .hourly)
            return hourForecast
        }.value
        print("hourWeather = \(hourWeather?.count ?? 0)")
        return hourWeather
    }
    
    func convertCLL(_ coordinate: CLLocationCoordinate2D) -> CLLocation {
        return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    struct Forecasts: Identifiable {
        let id = UUID()
        let symbolName: String
        let minTemp: String
        let maxTemp: String
    }
}

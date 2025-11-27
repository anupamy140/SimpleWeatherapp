//
//  City.swift
//  SimpleWeatherapp
//
//  Created by Anupam Yadav on 23/11/25.
//

import Foundation

/// Simple model representing a city and its cached weather.
struct City: Codable {
    let name: String
    var lastWeather: WeatherResponse?
    var lastUpdated: Date?
}

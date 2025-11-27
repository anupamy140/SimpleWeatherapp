//
//  WeatherViewModel.swift
//  SimpleWeatherapp
//
//  Created by Anupam Yadav on 25/11/25.
//

import Foundation

/// ViewModel for the weather details screen.
final class WeatherViewModel {

    // MARK: - Inputs / state

    /// Name of the city whose weather we show.
    var cityName: String?

    /// Last successful weather response (used as cache).
    var cachedWeather: WeatherResponse?

    /// When that cache was last updated.
    var lastUpdated: Date?

    // MARK: - Dependencies

    private let api: WeatherAPI
    private let cityStore: CityStore

    // MARK: - Outputs (callbacks to the ViewController)

    /// Called with `true` when loading starts, `false` when it stops.
    var onLoadingStateChange: ((Bool) -> Void)?

    /// Called when we have new weather to show.
    var onWeatherUpdated: ((WeatherResponse, Date?) -> Void)?

    /// Called when we want to show an alert.
    var onShowMessage: ((String, String) -> Void)?

    /// Called once when there is a city but no cached weather yet.
    var onShowFirstTimeMessage: ((String) -> Void)?

    /// Called to show some status text on the screen.
    var onShowStatusText: ((String) -> Void)?

    // MARK: - Init

    init(cityName: String?,
         cachedWeather: WeatherResponse?,
         lastUpdated: Date?,
         api: WeatherAPI = .shared,
         cityStore: CityStore = .shared) {

        self.cityName = cityName
        self.cachedWeather = cachedWeather
        self.lastUpdated = lastUpdated
        self.api = api
        self.cityStore = cityStore
    }

    // MARK: - Initial state

    /// Called from `viewDidLoad` of the detail screen.
    /// Decides what to show before the first API call.
    func handleInitialState() {
        if let cached = cachedWeather {
            // We already have weather -> show it immediately.
            onWeatherUpdated?(cached, lastUpdated)
        } else if let name = cityName {
            // City chosen but no weather yet.
            onShowFirstTimeMessage?(name)
        } else {
            // No city at all.
            onShowStatusText?("Pick a city from the list first.")
        }
    }

    // MARK: - Refresh weather (for THIS city only)

    /// Refreshes weather for the current city.
    ///
    /// - Parameter typedCity:
    ///   Optional manual override (e.g. from a text field).
    ///   In your app you always pass `nil`, so it uses `cityName`
    ///   injected from `CityListViewController`.
    func refreshWeather(using typedCity: String?) {
        // Prefer the view model's cityName; fall back to typedCity.
        let chosenName = cityName ?? typedCity ?? ""
        let city = chosenName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !city.isEmpty else {
            onShowMessage?("City needed", "Please select a city first.")
            return
        }

        // Make sure our state knows which city we are for.
        cityName = city

        // Tell VC we started loading.
        onLoadingStateChange?(true)
        onShowStatusText?("Updating latest weather…")

        api.fetchWeather(for: city) { [weak self] result in
            guard let self = self else { return }

            // Loading finished.
            self.onLoadingStateChange?(false)

            switch result {
            case .success(let weather):
                // Update our cache.
                self.lastUpdated = Date()
                self.cachedWeather = weather

                // Persist to Core Data so city list shows fresh data.
                self.cityStore.updateWeather(for: city, with: weather)

                // Tell the screen to update.
                self.onWeatherUpdated?(weather, self.lastUpdated)

            case .failure(let error):
                self.onShowMessage?(
                    "Error",
                    "Could not load weather.\n\(error.localizedDescription)"
                )

                if let cached = self.cachedWeather {
                    // Keep old cached data if we have it.
                    self.onWeatherUpdated?(cached, self.lastUpdated)
                } else {
                    // No cache → show failure text.
                    self.onShowStatusText?("Last update failed")
                }
            }
        }
    }
}

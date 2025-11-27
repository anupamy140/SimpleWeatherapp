import Foundation

/// ViewModel for the list of cities screen.
final class CityListViewModel {

    private let cityStore: CityStore
    private let weatherAPI: WeatherAPI

    init(cityStore: CityStore = .shared,
         weatherAPI: WeatherAPI = .shared) {
        self.cityStore = cityStore
        self.weatherAPI = weatherAPI
    }

    var numberOfRows: Int {
        cityStore.cities.count
    }

    func city(at index: Int) -> City {
        cityStore.cities[index]
    }

    /// Old simple add, if you still want to use it anywhere.
    func addCity(named name: String) {
        cityStore.addCity(named: name)
    }

    /// New: add city AND fetch weather from OpenWeather, then save into Core Data.
    func addCityAndFetchWeather(
        named rawName: String,
        completion: ((Error?) -> Void)? = nil
    ) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            completion?(nil)
            return
        }

        // 1. Add city name so it appears in the list
        cityStore.addCity(named: name)

        // 2. Fetch weather from OpenWeather
        weatherAPI.fetchWeather(for: name) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let weather):
                // 3. Save weather into Core Data
                self.cityStore.updateWeather(for: name, with: weather)
                completion?(nil)

            case .failure(let error):
                completion?(error)
            }
        }
    }

    func deleteCity(at index: Int) {
        cityStore.deleteCity(at: index)
    }
    func refreshAllCities(completion: @escaping () -> Void) {
        let group = DispatchGroup()

        // Take a snapshot so the array doesn't change while we loop
        let currentCities = cityStore.cities

        // If there are no cities, just call completion
        guard !currentCities.isEmpty else {
            completion()
            return
        }

        for city in currentCities {
            group.enter()

            WeatherAPI.shared.fetchWeather(for: city.name) { [weak self] result in
                switch result {
                case .success(let weather):
                    // update Core Data + in-memory list
                    self?.cityStore.updateWeather(for: city.name, with: weather)
                case .failure(let error):
                    print("❌ Failed to refresh weather for \(city.name):", error)
                }

                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion()
        }
    }


}

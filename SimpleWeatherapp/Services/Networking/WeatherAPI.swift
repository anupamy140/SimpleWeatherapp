//
//  WeatherAPI.swift
//  SimpleWeatherapp
//
//  Created by Anupam Yadav on 22/11/25.
//
import Foundation

enum WeatherError: Error {
    case invalidURL
    case noData
    case decodingFailed
}

final class WeatherAPI {

    static let shared = WeatherAPI()

    // 👇 put your real OpenWeather API key here
    private let apiKey = "c99e87039272851c36ad46c6c405c35b"

    func fetchWeather(for city: String,
                      completion: @escaping (Result<WeatherResponse, Error>) -> Void) {

        // Build URL safely with URLComponents (avoids mistakes in string)
        var components = URLComponents(string: "https://api.openweathermap.org/data/2.5/weather")
        components?.queryItems = [
            URLQueryItem(name: "q", value: city),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric")
        ]

        guard let url = components?.url else {
            completion(.failure(WeatherError.invalidURL))
            return
        }

        print("➡️ Requesting:", url.absoluteString)

        URLSession.shared.dataTask(with: url) { data, response, error in

            if let error = error {
                // Extra debug info in console
                print("❌ URLSession error:", error)
                if let urlError = error as? URLError {
                    print("URLError code:", urlError.code.rawValue)
                }
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(WeatherError.noData)) }
                return
            }

            do {
                let decoder = JSONDecoder()
                let weather = try decoder.decode(WeatherResponse.self, from: data)
                DispatchQueue.main.async { completion(.success(weather)) }
            } catch {
                print("❌ Decoding error:", error)
                DispatchQueue.main.async {
                    completion(.failure(WeatherError.decodingFailed))
                }
            }

        }.resume()
    }
}

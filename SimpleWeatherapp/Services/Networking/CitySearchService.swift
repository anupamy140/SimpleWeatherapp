import Foundation

struct CitySuggestion {
    let name: String      // e.g. "Delhi"
    let country: String   // e.g. "India"
    let state: String?    // e.g. "Delhi" or "Tamil Nadu"

    var displayName: String {
        if let state = state, !state.isEmpty {
            return "\(name), \(state), \(country)"
        } else {
            return "\(name), \(country)"
        }
    }
}

enum CitySearchError: Error {
    case invalidURL
}

/// Uses Open-Meteo Geocoding API for city suggestions.
final class CitySearchService {

    static let shared = CitySearchService()
    private init() {}

    func searchCities(
        matching query: String,
        completion: @escaping (Result<[CitySuggestion], Error>) -> Void
    ) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            DispatchQueue.main.async { completion(.success([])) }
            return
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host   = "geocoding-api.open-meteo.com"
        components.path   = "/v1/search"
        components.queryItems = [
            URLQueryItem(name: "name", value: trimmed),
            URLQueryItem(name: "count", value: "100"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components.url else {
            print("🔴 CitySearchService: invalid URL components for query:", trimmed)
            DispatchQueue.main.async {
                completion(.failure(CitySearchError.invalidURL))
            }
            return
        }

        print("🌍 CitySearchService: Requesting =", url.absoluteString)

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let http = response as? HTTPURLResponse {
                print("🌍 CitySearchService: HTTP status =", http.statusCode)
            }

            if let error = error {
                print("🔴 CitySearchService: request error =", error.localizedDescription)
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data else {
                print("⚠️ CitySearchService: no data returned")
                DispatchQueue.main.async { completion(.success([])) }
                return
            }

            // Optional: uncomment this to see raw JSON
            // print("📦 CitySearchService raw JSON:", String(data: data, encoding: .utf8) ?? "nil")

            struct GeocodingResponse: Decodable {
                let results: [GeocodingItem]?
            }

            struct GeocodingItem: Decodable {
                let name: String
                let country: String
                let admin1: String?
            }

            do {
                let decoded = try JSONDecoder().decode(GeocodingResponse.self, from: data)
                let items = decoded.results ?? []
                let suggestions = items.map {
                    CitySuggestion(
                        name: $0.name,
                        country: $0.country,
                        state: $0.admin1
                    )
                }

                print("✅ CitySearchService: got \(suggestions.count) suggestions for \"\(trimmed)\"")

                DispatchQueue.main.async {
                    completion(.success(suggestions))
                }
            } catch {
                print("🔴 CitySearchService: JSON decode error =", error)
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }

        task.resume()
    }
}

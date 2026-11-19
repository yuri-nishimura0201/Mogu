import Foundation

struct HotPepperAPIService {
    func fetchRestaurants(
        latitude: Double,
        longitude: Double,
        apiKey: String,
        range: Int = 3,
        genres: Set<String> = [],
        budget: String? = nil,
        openingHours: OpeningHoursFilter = .all,
        partyCapacity: Int? = nil,
        partyOptions: Set<PartyOption> = [],
        preferences: Set<PreferenceOption> = [],
        start: Int = 1
    ) async throws -> [Restaurant] {

        var components = URLComponents(
            string: "https://webservice.recruit.co.jp/hotpepper/gourmet/v1/"
        )!

        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lng", value: String(longitude)),
            URLQueryItem(name: "range", value: String(range)),
            URLQueryItem(name: "count", value: "40"),
            URLQueryItem(name: "start", value: String(start)),
            URLQueryItem(name: "format", value: "json")
        ]

        for genre in genres.sorted() {
            components.queryItems?.append(
                URLQueryItem(name: "genre", value: genre)
            )
        }

        if let budget = budget {
            components.queryItems?.append(
                URLQueryItem(name: "budget", value: budget)
            )
        }

        switch openingHours {
        case .all:
            break

        case .lunch:
            components.queryItems?.append(
                URLQueryItem(name: "lunch", value: "1")
            )

        case .after23:
            components.queryItems?.append(
                URLQueryItem(name: "midnight", value: "1")
            )

        case .mealAfter23:
            components.queryItems?.append(
                URLQueryItem(name: "midnight_meal", value: "1")
            )
        }

        if let partyCapacity = partyCapacity {
            components.queryItems?.append(
                URLQueryItem(name: "party_capacity", value: String(partyCapacity))
            )
        }

        for option in partyOptions.sorted(by: { $0.rawValue < $1.rawValue }) {
            components.queryItems?.append(
                URLQueryItem(name: option.rawValue, value: "1")
            )
        }

        for preference in preferences.sorted(by: { $0.rawValue < $1.rawValue }) {
            components.queryItems?.append(
                URLQueryItem(name: preference.rawValue, value: "1")
            )
        }

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, urlResponse) = try await URLSession.shared.data(from: url)

        guard let httpResponse = urlResponse as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        let decodedResponse = try JSONDecoder().decode(
            RestaurantResponse.self,
            from: data
        )

        return decodedResponse.results.shop
    }
}

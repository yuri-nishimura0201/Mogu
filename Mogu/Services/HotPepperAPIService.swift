import Foundation
import CoreLocation

struct HotPepperAPIService {
    static let pageSize = 40
    private let apiKey: String

    init() throws { //正しくAPIキーが設定されているか
        guard let key = Bundle.main.object(forInfoDictionaryKey: "HOTPEPPER_API_KEY") as? String,
              !key.isEmpty, !key.contains("$(") else {
            throw SearchIssue.configuration
        }
        apiKey = key
    }

    //検索
    func fetchRestaurants(
        filters: SearchFilters,
        coordinate: CLLocationCoordinate2D,
        start: Int = 1
    ) async throws -> [Restaurant] {

        let locationItems = [
            URLQueryItem(name: "lat", value: String(coordinate.latitude)),
            URLQueryItem(name: "lng", value: String(coordinate.longitude)),
            URLQueryItem(name: "range", value: String(filters.range.apiCode))
        ]
        return try await fetchRestaurants(filters: filters, searchItems: locationItems, start: start)
    }

    func matchingRestaurantIDs(_ ids: [String], filters: SearchFilters) async throws -> Set<String> {
        let batchSize = 20 // グルメサーチAPIで一度に指定できる店舗IDの上限
        var matchedIDs: Set<String> = []
        for start in stride(from: 0, to: ids.count, by: batchSize) {
            try Task.checkCancellation()
            let end = min(start + batchSize, ids.count)
            let idItem = URLQueryItem(name: "id", value: ids[start..<end].joined(separator: ","))
            let shops = try await fetchRestaurants(filters: filters, searchItems: [idItem], start: 1)
            matchedIDs.formUnion(shops.map(\.id))
        }
        return matchedIDs
    }

    private func fetchRestaurants(
        filters: SearchFilters,
        searchItems: [URLQueryItem],
        start: Int
    ) async throws -> [Restaurant] {
        var components = URLComponents(
            string: "https://webservice.recruit.co.jp/hotpepper/gourmet/v1/"
        )!

        components.queryItems = searchItems + [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "count", value: String(Self.pageSize)),
            URLQueryItem(name: "start", value: String(start)),
            URLQueryItem(name: "format", value: "json")
        ]
        let searchName = filters.restaurantName.trimmingCharacters(in: .whitespacesAndNewlines)

        if !searchName.isEmpty {
            components.queryItems?.append(
                URLQueryItem(name: "name", value: searchName)
            )
        }

        for genre in filters.selectedGenres.sorted() {
            components.queryItems?.append(
                URLQueryItem(name: "genre", value: genre)
            )
        }

        if let budget = filters.budget {
            components.queryItems?.append(
                URLQueryItem(name: "budget", value: budget)
            )
        }

        switch filters.openingHours {
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

        if let partyCapacity = filters.partyCapacity {
            components.queryItems?.append(
                URLQueryItem(name: "party_capacity", value: String(partyCapacity))
            )
        }

        for option in filters.selectedPartyOptions.sorted(by: { $0.rawValue < $1.rawValue }) {
            components.queryItems?.append(
                URLQueryItem(name: option.rawValue, value: "1")
            )
        }

        for preference in filters.selectedPreferences.sorted(by: { $0.rawValue < $1.rawValue }) {
            components.queryItems?.append(
                URLQueryItem(name: preference.rawValue, value: "1")
            )
        }

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, urlResponse) = try await URLSession.shared.data(from: url)

        //HTTPステータスコードの確認
        guard let httpResponse = urlResponse as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        //JSON→Restaurant型
        let decodedResponse = try JSONDecoder().decode(
            RestaurantResponse.self,
            from: data
        )

        let results = decodedResponse.results
        if let errors = results.error, !errors.isEmpty {
            if errors.contains(where: { $0.code == 2000 }) {
                throw SearchIssue.authentication
            }
            throw URLError(.badServerResponse)
        }
        guard let shops = results.shop else {
            throw URLError(.badServerResponse)
        }
        return shops
    }
}

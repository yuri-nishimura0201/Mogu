//
//  HotPepperAPIService.swift
//  Mogu
//
//  Created by cmStudent on 2026/11/14.
//
import Foundation

struct HotPepperAPIService {

    func fetchRestaurants(
        latitude: Double,
        longitude: Double,
        apiKey: String,
        genre: String? = nil
    ) async throws -> [Restaurant] {

        var components = URLComponents(
            string: "https://webservice.recruit.co.jp/hotpepper/gourmet/v1/"
        )!

        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lng", value: String(longitude)),
            URLQueryItem(name: "range", value: "3"),
            URLQueryItem(name: "count", value: "40"),
            URLQueryItem(name: "format", value: "json")
        ]

        if let genre = genre {
            components.queryItems?.append(
                URLQueryItem(name: "genre", value: genre)
            )
        }

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        let response = try JSONDecoder().decode(
            RestaurantResponse.self,
            from: data
        )

        return response.results.shop
    }
}

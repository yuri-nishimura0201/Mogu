
import Foundation
import Combine

final class FavoritesStore: ObservableObject {
    @Published private(set) var favoriteIDs: Set<String> = []
    @Published private(set) var favoriteRestaurants: [Restaurant] = []

    private let storageKey = "favoriteRestaurantIDs"
    private let restaurantsStorageKey = "favoriteRestaurants"

    init() {
        let savedIDs = UserDefaults.standard.stringArray(
            forKey: storageKey
        ) ?? []

        favoriteIDs = Set(savedIDs)

        if let data = UserDefaults.standard.data(
            forKey: restaurantsStorageKey
        ) {
            do {
                favoriteRestaurants = try JSONDecoder().decode(
                    [Restaurant].self,
                    from: data
                )
            } catch {
                print("お気に入りの読み込みエラー: \(error)")
            }
        }

        favoriteIDs.formUnion(favoriteRestaurants.map(\.id))
    }

    func isFavorite(_ restaurantID: String) -> Bool {
        favoriteIDs.contains(restaurantID)
    }

    func toggleFavorite(_ restaurant: Restaurant) {
        if favoriteIDs.contains(restaurant.id) {
            favoriteIDs.remove(restaurant.id)
            favoriteRestaurants.removeAll { $0.id == restaurant.id }
        } else {
            favoriteIDs.insert(restaurant.id)
            favoriteRestaurants.append(restaurant)
        }

        saveFavorites()
    }

    func removeAll() {
        favoriteIDs.removeAll()
        favoriteRestaurants.removeAll()
        saveFavorites()
    }

    private func saveFavorites() {
        UserDefaults.standard.set(
            Array(favoriteIDs),
            forKey: storageKey
        )

        do {
            let data = try JSONEncoder().encode(favoriteRestaurants)
            UserDefaults.standard.set(
                data,
                forKey: restaurantsStorageKey
            )
        } catch {
            print("お気に入りの保存エラー: \(error)")
        }
    }
}

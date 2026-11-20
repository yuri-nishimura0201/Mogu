
import SwiftUI
import MapKit

struct FavoritesView: View {
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @State private var filters = SearchFilters()
    @State private var showSearchFilter = false
    @State private var randomRestaurant: Restaurant?
    @State private var showNoResultsAlert = false
    @State private var candidateRestaurant: Restaurant?
    @StateObject private var locationService = LocationService()
    @State private var matchedFavoriteIDs: Set<String>?

    private var requiresAPISearch: Bool {
        switch filters.openingHours {
        case .all:
            return filters.partyCapacity != nil ||
                !filters.selectedPartyOptions.isEmpty ||
                !filters.selectedPreferences.isEmpty
        case .lunch, .after23, .mealAfter23:
            return true
        }
    }

    private func isWithinRange(
        restaurant: Restaurant,
        latitude: Double,
        longitude: Double,
        radius: Double
    ) -> Bool {

        let searchLocation = CLLocation(
            latitude: latitude,
            longitude: longitude
        )

        let restaurantLocation = CLLocation(
            latitude: restaurant.lat,
            longitude: restaurant.lng
        )

        let distance = searchLocation.distance(
            from: restaurantLocation
        )

        return distance <= radius
    }

    private func searchFavoriteRestaurants() async {
        guard requiresAPISearch else {
            matchedFavoriteIDs = nil
            return
        }

        guard let apiKey else { return }

        let favoriteIDs = Set(
            favoritesStore.favoriteRestaurants.map(\.id)
        )

        guard !favoriteIDs.isEmpty else {
            matchedFavoriteIDs = []
            return
        }

        let coordinate: CLLocationCoordinate2D

        switch filters.location {
        case .station(_, let latitude, let longitude):
            coordinate = CLLocationCoordinate2D(
                latitude: latitude,
                longitude: longitude
            )
        case .currentLocation, .unspecified:
            guard let current = locationService.coordinate else {
                print("現在地を取得できませんでした")
                return
            }
            coordinate = current
        }

        do {
            var allResults: [Restaurant] = []
            var start = 1

            repeat {
                let results = try await HotPepperAPIService().fetchRestaurants(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    apiKey: apiKey,
                    range: filters.range == 0 ? 5 : filters.range,
                    genres: filters.selectedGenres,
                    budget: filters.budget,
                    openingHours: filters.openingHours,
                    partyCapacity: filters.partyCapacity,
                    partyOptions: filters.selectedPartyOptions,
                    preferences: filters.selectedPreferences,
                    start: start
                )

                allResults.append(contentsOf: results)
                start += results.count

                if results.count < 40 {
                    break
                }
            } while start <= 1000

            matchedFavoriteIDs = Set(
                allResults.map(\.id).filter { favoriteIDs.contains($0) }
            )

        } catch {
            print("お気に入り検索エラー: \(error)")
        }
    }


    private var filteredRestaurants: [Restaurant] {
        favoritesStore.favoriteRestaurants.filter { restaurant in

            let matchesGenre =
                filters.selectedGenres.isEmpty ||
                (restaurant.genre.code.map {
                    filters.selectedGenres.contains($0)
                } ?? false)

            let matchesBudget =
                filters.budget == nil ||
                restaurant.budget.code == filters.budget

            let matchesDistance: Bool

            switch filters.location {
            case .station(_, let latitude, let longitude):

                let radius = Double(
                    [0, 300, 500, 1000, 2000, 3000][filters.range]
                )

                matchesDistance = filters.range == 0 ||
                    isWithinRange(
                        restaurant: restaurant,
                        latitude: latitude,
                        longitude: longitude,
                        radius: radius
                    )

            case .currentLocation:
                if filters.range == 0 {
                    matchesDistance = true
                } else if let coordinate = locationService.coordinate {
                    let distances = [0, 300, 500, 1000, 2000, 3000]
                    let radius = Double(distances[filters.range])

                    matchesDistance = isWithinRange(
                        restaurant: restaurant,
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        radius: radius
                    )
                } else {
                    matchesDistance = false
                }

            case .unspecified:
                matchesDistance = true

            }
            let matchesAPI =
                matchedFavoriteIDs?.contains(restaurant.id) ?? true

            return matchesGenre && matchesBudget && matchesDistance && matchesAPI
        }
    }

    private var apiKey: String? {
        guard let key = Bundle.main.object(
            forInfoDictionaryKey: "HOTPEPPER_API_KEY"
        ) as? String,
        !key.isEmpty,
        !key.contains("$(") else {
            return nil
        }

        return key
    }


    var body: some View {
        NavigationStack {
            Group {
                if showSearchFilter {
                    SearchFilterView(
                        filters: $filters,
                        showSearchFilter: $showSearchFilter,
                        source: .favorites,
                        onRandom: {
                            if let restaurant = RestaurantRandomizer.pick(
                                from: filteredRestaurants
                            ) {
                                randomRestaurant = restaurant
                            } else {
                                showNoResultsAlert = true
                            }
                        }
                    )
                } else {
                    if favoritesStore.favoriteRestaurants.isEmpty {
                        ContentUnavailableView(
                            "お気に入りはまだありません",
                            systemImage: "heart",
                            description: Text("気になるお店をお気に入りに追加してみよう")
                        )
                    } else if filteredRestaurants.isEmpty {
                        ContentUnavailableView(
                            "条件に合うお店がありません",
                            systemImage: "magnifyingglass",
                            description: Text("絞り込み条件を変更してみてください")
                        )
                    } else {
                        List {
                            ForEach(filteredRestaurants) { restaurant in
                                HStack(spacing: 8) {
                                    NavigationLink {
                                        RestaurantDetailView(restaurant: restaurant)
                                    } label: {
                                        HStack(spacing: 12) {
                                            AsyncImage(
                                                url: URL(string: restaurant.photo.mobile.s)
                                            ) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            } placeholder: {
                                                Image(systemName: "fork.knife")
                                                    .foregroundStyle(.brown)
                                            }
                                            .frame(width: 80, height: 80)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 10))

                                            VStack(alignment: .leading, spacing: 5) {
                                                Text(restaurant.name)
                                                    .font(.subheadline)
                                                    .bold()
                                                    .lineLimit(2)

                                                Text(restaurant.genre.name)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)

                                                Text(restaurant.budget.name)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        favoritesStore.toggleFavorite(restaurant)
                                    } label: {
                                        Image(systemName: "heart.fill")
                                            .font(.title3)
                                            .foregroundStyle(.red)
                                            .frame(width: 44, height: 44)
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        candidateRestaurant = restaurant
                                    } label: {
                                        Image(systemName: "list.bullet.circle")
                                            .font(.system(size: 24))
                                            .foregroundColor(.brown)
                                            .frame(width: 44, height: 44)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("お気に入り")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !showSearchFilter {
                        Button {
                            showSearchFilter = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.brown)
                        }
                    }
                }

            }

            .navigationDestination(isPresented: Binding(
                get: { randomRestaurant != nil },
                set: { if !$0 { randomRestaurant = nil } }
            )) {

                if let restaurant = randomRestaurant {
                    RandomRestaurantView(
                        restaurant: restaurant,
                        onRetry: {
                            randomRestaurant = RestaurantRandomizer.pick(
                                from: filteredRestaurants,
                                excluding: randomRestaurant?.id
                            )
                        }

                    )
                }
            }
        }
        .task(id: showSearchFilter) {
            guard !showSearchFilter else { return }
            await searchFavoriteRestaurants()
        }
        .task(id: favoritesStore.favoriteIDs) {
            guard !showSearchFilter else { return }
            await searchFavoriteRestaurants()
        }

        .onAppear {
            locationService.requestLocation()
        }

        .sheet(item: $candidateRestaurant) { restaurant in
            CandidateSelectionView(restaurant: restaurant)
        }

        .alert("該当する店舗がありません", isPresented: $showNoResultsAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("絞り込み条件を変更して、もう一度お試しください。")
        }
    }
}

#Preview {
    FavoritesView()
        .environmentObject(FavoritesStore())
        .environmentObject(CandidateStore())
}

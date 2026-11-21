
import SwiftUI
import MapKit

struct FavoritesView: View {
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @State private var filters = SearchFilters()
    @State private var showSearchFilter = false
    @State private var randomRestaurant: Restaurant?
    @State private var candidateRestaurant: Restaurant?
    @State private var searchIssue: SearchIssue?
    @State private var isPicking = false
    @State private var drawCandidates: [Restaurant] = []
    @StateObject private var locationService = LocationService()
    @State private var matchedFavoriteIDs: Set<String>?

    private struct ListSearchKey: Equatable {
        let favoriteIDs: Set<String>
        let hasLocation: Bool
        let locationUnavailable: Bool
    }

    private var listSearchKey: ListSearchKey? {
        guard !showSearchFilter else { return nil }
        return ListSearchKey(favoriteIDs: favoritesStore.favoriteIDs,
                             hasLocation: locationService.coordinate != nil,
                             locationUnavailable: locationService.locationUnavailable)
    }

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

    private func matchingIDs() async throws -> Set<String>? {
        guard requiresAPISearch else {
            return nil
        }

        guard let apiKey = HotPepperAPIService.apiKey else { throw SearchIssue.configuration }

        let favoriteIDs = Set(
            favoritesStore.favoriteRestaurants.map(\.id)
        )

        guard !favoriteIDs.isEmpty else {
            return []
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
                throw SearchIssue.location
            }
            coordinate = current
        }

        var matchedIDs: Set<String> = []
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

            for restaurant in results where favoriteIDs.contains(restaurant.id) {
                matchedIDs.insert(restaurant.id)
            }
            start += results.count

            if results.count < 40 {
                break
            }
        } while start <= 1000

        return matchedIDs
    }


    private func matchingFavorites(ids: Set<String>?) -> [Restaurant] {
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
                ids?.contains(restaurant.id) ?? true

            return matchesGenre && matchesBudget && matchesDistance && matchesAPI
        }
    }

    private var filteredRestaurants: [Restaurant] {
        matchingFavorites(ids: matchedFavoriteIDs)
    }

    private func updateResults(forDraw: Bool) async {
        if forDraw {
            guard !isPicking else { return }
            isPicking = true
        }
        defer { if forDraw { isPicking = false } }
        do {
            if case .currentLocation = filters.location, filters.range > 0,
               locationService.coordinate == nil { throw SearchIssue.location }
            let ids = try await matchingIDs()
            try Task.checkCancellation()
            if forDraw {
                drawCandidates = matchingFavorites(ids: ids)
                guard let pick = RestaurantRandomizer.pick(from: drawCandidates) else {
                    searchIssue = .noResults
                    return
                }
                randomRestaurant = pick
            } else {
                matchedFavoriteIDs = ids
            }
        } catch {
            guard !Task.isCancelled else { return }
            if !forDraw { matchedFavoriteIDs = [] }
            searchIssue = (error as? SearchIssue) ?? .connection
        }
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
                            Task { await updateResults(forDraw: true) }
                        }
                    )
                    .disabled(isPicking)
                    .overlay { if isPicking { ProgressView("候補を確認中") } }
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
                                                    .foregroundStyle(Color.moguInk)
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
                                            .font(.title3)
                                            .foregroundStyle(Color.moguInk)
                                            .frame(width: 44, height: 44)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("候補リストに追加")


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
                                .foregroundStyle(Color.moguInk)
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
                                from: drawCandidates,
                                excluding: randomRestaurant?.id
                            )
                        }

                    )
                }
            }
        }
        .task(id: listSearchKey) {
            guard !showSearchFilter else { return }
            if case .station = filters.location {
                await updateResults(forDraw: false)
            } else if !requiresAPISearch || locationService.coordinate != nil || locationService.locationUnavailable {
                await updateResults(forDraw: false)
            }
        }

        .onAppear {
            locationService.requestLocation()
        }

        .sheet(item: $candidateRestaurant) { restaurant in
            CandidateSelectionView(restaurant: restaurant)
        }
        .alert(item: $searchIssue) { issue in
            issue.alert {
                showSearchFilter = true
            } retry: {
                Task { await updateResults(forDraw: showSearchFilter) }
            }
        }
    }
}

#Preview {
    FavoritesView()
        .environmentObject(FavoritesStore())
        .environmentObject(CandidateStore())
}


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

    private func matchingIDs() async throws -> Set<String>? {
        if case .currentLocation = filters.location, filters.range != .unspecified,
           locationService.coordinate == nil { throw SearchIssue.location }

        guard requiresAPISearch else {
            return nil
        }

        let service = try HotPepperAPIService()

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

        // お気に入りの検索画面には店舗名の入力欄がない。
        var favoriteFilters = filters
        favoriteFilters.restaurantName = ""

        var matchedIDs: Set<String> = []
        var start = 1
        repeat {
            let results = try await service.fetchRestaurants(
                filters: favoriteFilters,
                coordinate: coordinate,
                start: start
            )

            for restaurant in results where favoriteIDs.contains(restaurant.id) {
                matchedIDs.insert(restaurant.id)
            }
            start += results.count

            if matchedIDs == favoriteIDs || results.count < HotPepperAPIService.pageSize {
                break
            }
        } while start <= 1000

        return matchedIDs
    }

    private func matchesSearchRange(_ restaurant: Restaurant) -> Bool {
        guard let meters = filters.range.meters else { return true }
        let coordinate: CLLocationCoordinate2D
        switch filters.location {
        case .unspecified:
            return true
        case .station(_, let latitude, let longitude):
            coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        case .currentLocation:
            guard let current = locationService.coordinate else { return false }
            coordinate = current
        }

        let center = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return restaurant.distance(from: center) <= Double(meters)
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

            let matchesDistance = matchesSearchRange(restaurant)
            let matchesAPI =
                ids?.contains(restaurant.id) ?? true

            return matchesGenre && matchesBudget && matchesDistance && matchesAPI
        }
    }

    private func refreshFavoriteList() async {
        do {
            let ids = try await matchingIDs()
            try Task.checkCancellation()
            matchedFavoriteIDs = ids
        } catch {
            guard !Task.isCancelled else { return }
            matchedFavoriteIDs = []
            searchIssue = (error as? SearchIssue) ?? .connection
        }
    }

    private func pickRandomFavorite() async {
        guard !isPicking else { return }
        isPicking = true
        defer { isPicking = false }
        do {
            let ids = try await matchingIDs()
            try Task.checkCancellation()
            drawCandidates = matchingFavorites(ids: ids)
            guard let pick = RestaurantRandomizer.pick(from: drawCandidates) else {
                throw SearchIssue.noResults
            }
            randomRestaurant = pick
        } catch {
            guard !Task.isCancelled else { return }
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
                            Task { await pickRandomFavorite() }
                        }
                    )
                    .disabled(isPicking)
                    .overlay { if isPicking { ProgressView("候補を確認中") } }
                } else {
                    let filteredRestaurants = matchingFavorites(ids: matchedFavoriteIDs)
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
                                        RestaurantRow(restaurant: restaurant, style: .favorites)
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
                await refreshFavoriteList()
            } else if !requiresAPISearch || locationService.coordinate != nil || locationService.locationUnavailable {
                await refreshFavoriteList()
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
                Task {
                    if showSearchFilter {
                        await pickRandomFavorite()
                    } else {
                        await refreshFavoriteList()
                    }
                }
            }
        }
    }
}

#Preview {
    FavoritesView()
        .environmentObject(FavoritesStore())
        .environmentObject(CandidateStore())
}

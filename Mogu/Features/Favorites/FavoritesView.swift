
import SwiftUI
import CoreLocation

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

    //取得状態が変化した際に検索を再実行する
    private struct ListSearchKey: Equatable {
        let favoriteIDs: Set<String>
        let hasLocation: Bool
        let locationUnavailable: Bool
    }

    private var usesCurrentLocation: Bool {
        if case .currentLocation = filters.location { return true }
        return false
    }

    private var listSearchKey: ListSearchKey? {
        //絞り込み条件の編集中は検索を実行しない
        guard !showSearchFilter else { return nil }
        return ListSearchKey(favoriteIDs: favoritesStore.favoriteIDs,
                             hasLocation: usesCurrentLocation && locationService.coordinate != nil,
                             locationUnavailable: usesCurrentLocation && locationService.locationUnavailable)
    }

    //お気に入りの絞り込みにAPIへの問い合わせが必要か判定する
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

    //APIの検索結果とお気に入り店舗のIDを照合する
    //nilはAPI検索不要、空のsetは該当店舗なし
    private func matchingIDs() async throws -> Set<String>? {
        if case .currentLocation = filters.location, filters.range != .unspecified,
           locationService.coordinate == nil { throw SearchIssue.location }

        guard requiresAPISearch else {
            return nil
        }

        let savedIDs = favoritesStore.favoriteRestaurants.map(\.id)
        guard !savedIDs.isEmpty else {
            return []
        }

        let service = try HotPepperAPIService()
        // お気に入りの検索画面には店舗名の入力欄がない。
        var favoriteFilters = filters
        favoriteFilters.restaurantName = ""

        let coordinate: CLLocationCoordinate2D
        switch filters.location {
        case .unspecified:
            return try await service.matchingRestaurantIDs(savedIDs, filters: favoriteFilters)
        case .station(_, let latitude, let longitude):
            coordinate = CLLocationCoordinate2D(
                latitude: latitude,
                longitude: longitude
            )
        case .currentLocation:
            guard let current = locationService.coordinate else {
                throw SearchIssue.location
            }
            coordinate = current
        }

        //１回のAPI通信では全件取得ができないため複数ページに分けて取得
        let favoriteIDs = Set(savedIDs)
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

            //お気に入りの全部、最終ページに到達したら通信の終了
            if matchedIDs == favoriteIDs || results.count < HotPepperAPIService.pageSize {
                break
            }
            //API通信の繰り返しに上限を設ける
        } while start <= 1000

        return matchedIDs
    }

    // お気に入りに保存した店舗情報とAPIの検索結果を使って絞り込む
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
            //キャンセルされた検索結果が画面に反映されないようにする
            try Task.checkCancellation()
            matchedFavoriteIDs = ids
        } catch {
            guard !Task.isCancelled else { return }
            matchedFavoriteIDs = []
            searchIssue = (error as? SearchIssue) ?? .connection
        }
    }

    private func pickRandomFavorite() async {
        //抽選処理の重複実行を防ぐ
        guard !isPicking else { return }
        isPicking = true
        //処理終了時の解除忘れを防ぐため、deferで抽選中の状態を解除する
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
        //検索キーが変化したら一覧を更新し以前のtaskをキャンセルする
        .task(id: listSearchKey) {
            guard !showSearchFilter else { return }
            if usesCurrentLocation, requiresAPISearch,
               locationService.coordinate == nil, !locationService.locationUnavailable { return }
            await refreshFavoriteList()
        }

        .onChange(of: usesCurrentLocation, initial: true) { _, needsLocation in
            if needsLocation { locationService.requestLocation() }
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


import SwiftUI
import MapKit
import Combine



struct HomeMapView: View {
    @ObservedObject var tutorial = MoguTutorial()
    @Environment(\.scenePhase) private var scenePhase
    @State private var candidateRestaurant: Restaurant?
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @StateObject private var locationService = LocationService()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapCenter: CLLocationCoordinate2D?
    @State private var showSearchButton = false
    @State private var showGenreLegend = false
    @State private var selectedRestaurant: Restaurant?
    @State private var searchIssue: SearchIssue?
    @State private var lastSearchCenter: CLLocationCoordinate2D?
    @State private var latestSearchID: UUID?
    @State private var isListExpanded = false
    @State private var highlightedRestaurantID: String?
    @Binding var filters: SearchFilters
    @Binding var showSearchFilter: Bool
    @Binding var restaurants: [Restaurant]
    @Binding var currentCoordinate: CLLocationCoordinate2D?

    private var tutorialFavoriteID: String? {
        guard tutorial.step == .favorite else { return nil }
        return restaurants.first { !favoritesStore.isFavorite($0.id) }?.id
    }

    private var showsExpandedList: Bool {
        switch tutorial.step {
        case .favorite, .candidate, .selecting: true
        default: isListExpanded
        }
    }

    var body: some View {
        MapReader { map in
            mapContent
                .overlayPreferenceValue(TutorialBounds.self) { anchors in
                    if let step = tutorial.step, scenePhase == .active,
                       [.palette, .legend, .pin, .filter, .favorite, .candidate].contains(step) {
                        GeometryReader { geometry in
                            TutorialSpotlight(step: step, target: spotlightRect(step, anchors, geometry, map),
                                              arrowTarget: step == .legend ? anchors[.palette]?.first.map { geometry[$0] } : nil,
                                              finish: tutorial.finish) {
                                switch step {
                                case .pin: tutorial.advance(from: .pin, to: .filter)
                                case .favorite: tutorial.advance(from: .favorite, to: .candidate)
                                case .candidate: tutorial.advance(from: .candidate, to: .random)
                                default: break
                                }
                            }
                        }
                    }
                }
        }
        .onChange(of: locationService.permissionResolved && scenePhase == .active, initial: true) { _, ready in
            if ready { tutorial.startIfNeeded() }
        }
        .onChange(of: tutorial.step) { _, step in
            if step == nil { showGenreLegend = false }
        }
    }

    private func spotlightRect(_ step: TutorialStep, _ anchors: TutorialBounds.Value,
                               _ geometry: GeometryProxy, _ map: MapProxy) -> CGRect? {
        func frames(_ key: TutorialTarget) -> [CGRect] {
            (anchors[key] ?? []).map { geometry[$0] }
        }
        switch step {
        case .palette: return frames(.palette).first
        case .legend: return frames(.legend).first
        case .filter: return frames(.filter).first
        case .favorite, .candidate:
            guard let viewport = frames(.listViewport).first else { return nil }
            return frames(step == .favorite ? .heart : .candidate).first { viewport.contains($0) }
        case .pin:
            // MapKitの座標変換で、上部ボタンと店舗一覧の間に見えるピンを選ぶ。
            let bottom = frames(.listViewport).first?.minY ?? geometry.size.height
            let origin = geometry.frame(in: .global).origin
            for shop in restaurants {
                let coordinate = CLLocationCoordinate2D(latitude: shop.lat, longitude: shop.lng)
                guard let point = map.convert(coordinate, to: .global) else { continue }
                let y = point.y - origin.y - (highlightedRestaurantID == shop.id ? 14 : 0)
                let rect = CGRect(x: point.x - origin.x - 20, y: y - 20, width: 40, height: 40)
                if rect.minY > 54, rect.maxY < bottom - 68,
                   rect.minX >= 0, rect.maxX <= geometry.size.width { return rect }
            }
            return nil
        default: return nil
        }
    }

    private var mapContent: some View {
        ZStack(alignment: .top) {

            Map(position: $cameraPosition) {
                ForEach(restaurants) { restaurant in
                    Annotation(
                        restaurant.name,
                        coordinate: CLLocationCoordinate2D(
                            latitude: restaurant.lat,
                            longitude: restaurant.lng
                        )
                    ) {
                        Button {
                            tutorial.advance(from: .pin, to: .detail)
                            focusOnRestaurant(restaurant)
                            selectedRestaurant = restaurant
                        } label: {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(
                                    RestaurantGenreColor.color(for: restaurant.genre.code)
                                )
                                .background(
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 38, height: 38)
                                        .shadow(
                                            color: .black.opacity(0.15),
                                            radius: 3,
                                            x: 0,
                                            y: 2
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(
                            highlightedRestaurantID == restaurant.id ? 1.6 : 1.0
                        )
                        .offset(
                            y: highlightedRestaurantID == restaurant.id ? -14 : 0
                        )
                    }
                    .mapOverlayLevel(
                        level: highlightedRestaurantID == restaurant.id
                            ? .aboveLabels
                            : .aboveRoads
                    )
                }
            }


            .onMapCameraChange(frequency: .onEnd) { context in

                mapCenter = context.region.center

                if let selectedID = highlightedRestaurantID,
                   let restaurant = restaurants.first(where: { $0.id == selectedID }) {

                    let mapLocation = CLLocation(
                        latitude: context.region.center.latitude,
                        longitude: context.region.center.longitude
                    )

                    let restaurantLocation = CLLocation(
                        latitude: restaurant.lat,
                        longitude: restaurant.lng
                    )

                    if mapLocation.distance(from: restaurantLocation) < 100 {
                        showSearchButton = false
                        return
                    }
                }

                showSearchButton = true
            }

            .onAppear {
                if let selectedID = highlightedRestaurantID,
                   let restaurant = restaurants.first(where: {
                       $0.id == selectedID
                   }) {
                    focusOnRestaurant(restaurant)
                } else {
                    applySearchLocation()
                }
            }



            .onReceive(locationService.$coordinate.compactMap { $0 }) { coordinate in

                currentCoordinate = coordinate

                if case .station = filters.location {
                    return
                }

                guard highlightedRestaurantID == nil else { return }

                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(
                            latitudeDelta: 0.01,
                            longitudeDelta: 0.01
                        )
                    )
                )

                Task {
                    await loadRestaurants(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude
                    )
                }
            }


            if showSearchButton {
                Button {
                    guard let center = mapCenter else { return }

                    showSearchButton = false

                    Task {
                        await loadRestaurants(
                            latitude: center.latitude,
                            longitude: center.longitude
                        )
                    }
                } label: {
                    Label("このエリアで再検索", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                        .bold()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.regularMaterial, in: Capsule())
                }
            }
            VStack {
                Spacer()

                VStack(spacing: 0) {

                    // ドラッグ用のつまみ
                    Capsule()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 40, height: 5)
                        .padding(.top, 10)
                        .padding(.bottom, 8)

                    ScrollViewReader { scroll in
                        restaurantList
                            .onChange(of: tutorialFavoriteID, initial: true) { _, id in
                                if let id { scroll.scrollTo(id, anchor: .center) }
                            }
                    }
                }
                .frame(
                    height: showsExpandedList ? 450 : 180,
                    alignment: .top
                )
                .frame(maxWidth: .infinity)
                .background(
                    Color.moguCanvas,
                    in: UnevenRoundedRectangle(
                        topLeadingRadius: 22,
                        topTrailingRadius: 22
                    )
                )
                .shadow(color: .black.opacity(0.12), radius: 8, y: -3)
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            withAnimation(.easeInOut(duration: 0.25)) {
                                if value.translation.height < -50 {
                                    isListExpanded = true
                                } else if value.translation.height > 50 {
                                    isListExpanded = false
                                }
                            }
                        }
                )
            }

        }

        .navigationDestination(
            isPresented: Binding(
                get: { selectedRestaurant != nil },
                set: { presented in
                    if !presented {
                        selectedRestaurant = nil
                        tutorial.advance(from: .detail, to: .filter)
                    }
                }
            )
        ) {
            if let restaurant = selectedRestaurant {
                RestaurantDetailView(restaurant: restaurant)
                    .overlay(alignment: .topLeading) {
                        if tutorial.step == .detail {
                            TutorialArrow(pointsDown: false)
                                .padding(.leading, 20)
                                .padding(.top, 6)
                        }
                    }
                    .safeAreaInset(edge: .bottom) {
                        if tutorial.step == .detail { TutorialHint(step: .detail, finish: tutorial.finish) }
                    }
            }
        }

        .toolbar(.hidden, for: .navigationBar)

        .overlay(alignment: .topLeading) {
            genreLegend
                .tutorialTarget(.legend, active: tutorial.step == .legend)
        }

        .overlay(alignment: .topTrailing) {
            Button {
                tutorial.advance(from: .filter, to: .editing)
                showSearchFilter = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .foregroundStyle(Color.moguInk)
                    .padding(12)
                    .background(.regularMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .tutorialTarget(.filter, active: tutorial.step == .filter)
            .padding(.trailing, 16)
        }

        .sheet(item: $candidateRestaurant, onDismiss: {
            tutorial.advance(from: .selecting, to: .random)
        }) { restaurant in
            CandidateSelectionView(restaurant: restaurant)
                .safeAreaInset(edge: .bottom) {
                    if tutorial.step == .selecting { TutorialHint(step: .selecting, finish: tutorial.finish) }
                }
        }
        .onReceive(locationService.$locationUnavailable) { unavailable in
            if case .station = filters.location { return }
            if unavailable && restaurants.isEmpty && !tutorial.isFirstLaunch && tutorial.step == nil {
                searchIssue = .location
            }
        }
        .alert(item: $searchIssue) { issue in
            issue.alert {
                showSearchFilter = true
            } retry: {
                if let center = lastSearchCenter {
                    Task { await loadRestaurants(latitude: center.latitude, longitude: center.longitude) }
                }
            }
        }
    }

    private var genreLegend: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showGenreLegend.toggle()
                    if showGenreLegend { tutorial.advance(from: .palette, to: .legend) }
                    else { tutorial.advance(from: .legend, to: .pin) }
                }
            } label: {
                Image(systemName: "paintpalette")
                    .font(.title3)
                    .foregroundStyle(Color.moguInk)
                    .frame(width: 44, height: 44)
                    .background(.regularMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("ジャンルの色")
            .tutorialTarget(.palette, active: tutorial.step == .palette || tutorial.step == .legend)

            if showGenreLegend {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(genreLegendItems.indices, id: \.self) { index in
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(
                                        RestaurantGenreColor.color(
                                            for: genreLegendItems[index].code
                                        )
                                    )
                                    .frame(width: 16, height: 16)

                                Text(genreLegendItems[index].name)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(14)
                }
                .frame(width: 240)
                .containerRelativeFrame(.vertical) { height, _ in
                    tutorial.step == .legend ? min(300, height * 0.5) : 300
                }
                .background(
                    .regularMaterial,
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .shadow(color: .black.opacity(0.12), radius: 5, y: 3)
            }
        }
        .padding(.leading, 16)
    }

    private let genreLegendItems: [(code: String, name: String)] = [
        ("G001", "居酒屋"),
        ("G002", "ダイニングバー・バル"),
        ("G003", "創作料理"),
        ("G004", "和食"),
        ("G005", "洋食"),
        ("G006", "イタリアン・フレンチ"),
        ("G007", "中華"),
        ("G008", "焼肉・ホルモン"),
        ("G009", "アジア・エスニック料理"),
        ("G010", "各国料理"),
        ("G011", "カラオケ・パーティ"),
        ("G012", "バー・カクテル"),
        ("G013", "ラーメン"),
        ("G014", "カフェ・スイーツ"),
        ("G015", "その他グルメ"),
        ("G016", "お好み焼き・もんじゃ"),
        ("G017", "韓国料理")
    ]



    private var restaurantList: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("近くのお店 \(restaurants.count)件")
                .font(.headline)
                .padding(.horizontal)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(restaurants) { restaurant in
                        HStack(spacing: 8) {
                            Button {
                                focusOnRestaurant(restaurant)
                                selectedRestaurant = restaurant
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
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(
                                                RestaurantGenreColor.color(for: restaurant.genre.code),
                                                lineWidth: 4
                                            )
                                    )
                                    .padding(.leading, 12)

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(restaurant.name)
                                            .font(.subheadline)
                                            .bold()
                                            .lineLimit(2)

                                        Text(restaurant.genre.name)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        Text("予算目安：\(restaurant.budget.name)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        Text(restaurant.open)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }

                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)

                            Button {
                                focusOnRestaurant(restaurant)
                            } label: {
                                Image(systemName: "mappin.circle")
                                    .font(.title3)
                                    .foregroundStyle(Color.moguInk)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(restaurant.name)を地図で表示")

                            Button {
                                favoritesStore.toggleFavorite(restaurant)
                                if favoritesStore.isFavorite(restaurant.id) {
                                    tutorial.advance(from: .favorite, to: .candidate)
                                }
                            } label: {
                                Image(
                                    systemName: favoritesStore.isFavorite(restaurant.id)
                                        ? "heart.fill"
                                        : "heart"
                                )
                                .font(.title3)
                                .foregroundStyle(.red)
                                .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .tutorialTarget(.heart, active: tutorial.step == .favorite && !favoritesStore.isFavorite(restaurant.id))

                            Button {
                                candidateRestaurant = restaurant
                                tutorial.advance(from: .candidate, to: .selecting)
                            } label: {
                                Image(systemName: "list.bullet.circle")
                                    .font(.title3)
                                    .foregroundStyle(Color.moguInk)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("候補リストに追加")
                            .tutorialTarget(.candidate, active: tutorial.step == .candidate)
                            .padding(.trailing, 12)
                        }
                        .id(restaurant.id)

                        Divider()
                    }
                }
            }
            .tutorialTarget(.listViewport, active: tutorial.step != nil)
        }
        .padding(.top, 16)
    }

    private func focusOnRestaurant(_ restaurant: Restaurant) {

        let coordinate = CLLocationCoordinate2D(
            latitude: restaurant.lat,
            longitude: restaurant.lng
        )

        withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
            highlightedRestaurantID = restaurant.id
            isListExpanded = false
        }

        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.008,
                        longitudeDelta: 0.008
                    )
                )
            )
        }
    }

    private func applySearchLocation() {
        showSearchButton = false

        switch filters.location {
        case .station(_, let latitude, let longitude):
            let coordinate = CLLocationCoordinate2D(
                latitude: latitude,
                longitude: longitude
            )
            mapCenter = coordinate
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.01,
                        longitudeDelta: 0.01
                    )
                )
            )

            Task {
                await loadRestaurants(
                    latitude: latitude,
                    longitude: longitude
                )
            }

        case .unspecified, .currentLocation:
            locationService.requestLocation()
        }
    }

    private func loadRestaurants(
        latitude: Double,
        longitude: Double
    ) async {
        let requestID = UUID()
        latestSearchID = requestID
        lastSearchCenter = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        guard let apiKey = HotPepperAPIService.apiKey else {
            if tutorial.step == nil { searchIssue = .configuration }
            return
        }

        do {
            let result = try await HotPepperAPIService().fetchRestaurants(
                latitude: latitude,
                longitude: longitude,
                apiKey: apiKey,
                range: filters.range == 0 ? 5 : filters.range,
                genres: filters.selectedGenres,
                budget: filters.budget,
                openingHours: filters.openingHours,
                partyCapacity: filters.partyCapacity,
                partyOptions: filters.selectedPartyOptions,
                preferences: filters.selectedPreferences,
                name: filters.restaurantName
            )

            let searchLocation = CLLocation(
                latitude: latitude,
                longitude: longitude
            )
            let sortedRestaurants = result.sorted {
                CLLocation(latitude: $0.lat, longitude: $0.lng)
                    .distance(from: searchLocation)
                <
                CLLocation(latitude: $1.lat, longitude: $1.lng)
                    .distance(from: searchLocation)
            }

            await MainActor.run {
                guard latestSearchID == requestID else { return }
                restaurants = sortedRestaurants
                searchIssue = sortedRestaurants.isEmpty && tutorial.step == nil ? .noResults : nil
                fitMapToRestaurants(sortedRestaurants)
            }
        } catch {
            guard latestSearchID == requestID else { return }
            if tutorial.step == nil { searchIssue = .connection }
        }
    }

    private func fitMapToRestaurants(_ restaurants: [Restaurant]) {
        guard !restaurants.isEmpty,
              let center = mapCenter else { return }

        let centerLocation = CLLocation(
            latitude: center.latitude,
            longitude: center.longitude
        )

        let nearby = restaurants.sorted {
            CLLocation(latitude: $0.lat, longitude: $0.lng)
                .distance(from: centerLocation)
            <
            CLLocation(latitude: $1.lat, longitude: $1.lng)
                .distance(from: centerLocation)
        }
        .prefix(6)

        let maxDistance = nearby.map {
            CLLocation(latitude: $0.lat, longitude: $0.lng)
                .distance(from: centerLocation)
        }.max() ?? 0

        let desiredDelta = min(
            max(maxDistance * 2.8 / 111_000, 0.005),
            0.02
        )

        let currentRegion = cameraPosition.region

        let latitudeDelta = max(
            currentRegion?.span.latitudeDelta ?? 0.005,
            desiredDelta
        )

        let longitudeDelta = max(
            currentRegion?.span.longitudeDelta ?? 0.005,
            desiredDelta
        )

        withAnimation(.easeInOut(duration: 0.4)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: center,
                    span: MKCoordinateSpan(
                        latitudeDelta: latitudeDelta,
                        longitudeDelta: longitudeDelta
                    )
                )
            )
        }
    }

}

#Preview {
    HomeMapView(
        filters: .constant(SearchFilters()),
        showSearchFilter: .constant(false),
        restaurants: .constant([]),
        currentCoordinate: .constant(nil)
    )
    .environmentObject(FavoritesStore())
    .environmentObject(CandidateStore())
}

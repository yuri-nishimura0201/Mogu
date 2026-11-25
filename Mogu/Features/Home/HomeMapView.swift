
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
    private enum MapDestination {
        case detail(Restaurant)
        case search
    }
    private static let compactList = PresentationDetent.height(180)
    private static let expandedList = PresentationDetent.height(450)
    @State private var showsList = false
    @State private var listHeight = compactList
    @State private var nextDestination: MapDestination?
    @State private var highlightedRestaurantID: String?
    @Binding var filters: SearchFilters
    @Binding var showSearchFilter: Bool
    @Binding var restaurants: [Restaurant]
    @Binding var currentCoordinate: CLLocationCoordinate2D?

    private var tutorialFavoriteID: String? {
        guard tutorial.step == .favorite else { return nil }
        return restaurants.first { !favoritesStore.isFavorite($0.id) }?.id
    }

    private var isListTutorial: Bool {
        tutorial.step == .favorite || tutorial.step == .candidate || tutorial.step == .selecting
    }

    var body: some View {
        MapReader { map in
            mapContent
                .overlayPreferenceValue(TutorialBounds.self) { anchors in
                    if let step = tutorial.step, scenePhase == .active,
                       [.palette, .legend, .pin, .filter].contains(step) {
                        GeometryReader { geometry in
                            TutorialSpotlight(step: step, target: spotlightRect(step, anchors, geometry, map),
                                              arrowTarget: step == .legend ? anchors[.palette]?.first.map { geometry[$0] } : nil,
                                              finish: tutorial.finish) {
                                tutorial.advance(from: .pin, to: .filter)
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
            if step == .favorite || step == .candidate {
                listHeight = Self.expandedList
                showsList = true
            } else if step == .palette {
                showsList = false
            }
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
        case .pin:
            // ピンの案内中は一覧シートを閉じ、画面内のピンを選ぶ。
            let origin = geometry.frame(in: .global).origin
            for shop in restaurants {
                let coordinate = CLLocationCoordinate2D(latitude: shop.lat, longitude: shop.lng)
                guard let point = map.convert(coordinate, to: .global) else { continue }
                let y = point.y - origin.y - (highlightedRestaurantID == shop.id ? 14 : 0)
                let rect = CGRect(x: point.x - origin.x - 20, y: y - 20, width: 40, height: 40)
                if rect.minY > 54, rect.maxY < geometry.size.height,
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
                            open(.detail(restaurant))
                        } label: {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(
                                    Genre.color(for: restaurant.genre.code)
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
                if isListTutorial {
                    listHeight = Self.expandedList
                    showsList = true
                } else if tutorial.step == nil && !tutorial.isFirstLaunch && searchIssue == nil {
                    showsList = true
                }
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
                        .glassEffect(.regular.interactive(), in: Capsule())
                }
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
                                .padding(.leading, 14)
                                .padding(.top, TutorialArrow.gap)
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
                open(.search)
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .foregroundStyle(Color.moguInk)
                    .padding(12)
                    .glassEffect(.regular.interactive(), in: Circle())
                    .frame(minWidth: 48, minHeight: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("検索・絞り込み")
            .tutorialTarget(.filter, active: tutorial.step == .filter)
            .padding(.trailing, 16)
        }

        .overlay(alignment: .bottom) {
            if !showsList && tutorial.step == nil {
                Button {
                    listHeight = Self.compactList
                    showsList = true
                } label: {
                    Label("近くのお店 \(restaurants.count)件", systemImage: "list.bullet")
                        .padding(.horizontal, 16)
                        .frame(minHeight: 44)
                        .background(.regularMaterial, in: Capsule())
                }
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showsList, onDismiss: {
            if let destination = nextDestination {
                nextDestination = nil
                navigate(to: destination)
            }
        }) {
            listSheet
        }
        .onReceive(locationService.$locationUnavailable) { unavailable in
            if case .station = filters.location { return }
            if unavailable && restaurants.isEmpty && !tutorial.isFirstLaunch && tutorial.step == nil {
                searchIssue = .location
            }
        }
        .alert(item: issueBinding(inList: false), content: searchAlert)
    }

    // 一覧表示中は最前面のシートからアラートを出す。
    private func issueBinding(inList: Bool) -> Binding<SearchIssue?> {
        Binding(get: { showsList == inList ? searchIssue : nil },
                set: { if showsList == inList { searchIssue = $0 } })
    }

    private func searchAlert(_ issue: SearchIssue) -> Alert {
        issue.alert {
            open(.search)
        } retry: {
            if let center = lastSearchCenter {
                Task { await loadRestaurants(latitude: center.latitude, longitude: center.longitude) }
            }
        }
    }

    private func open(_ destination: MapDestination) {
        if showsList {
            nextDestination = destination
            showsList = false
        } else {
            navigate(to: destination)
        }
    }

    private func navigate(to destination: MapDestination) {
        switch destination {
        case .detail(let restaurant):
            focusOnRestaurant(restaurant)
            selectedRestaurant = restaurant
        case .search:
            showSearchFilter = true
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
                    .glassEffect(.regular.interactive(), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("ジャンルの色")
            .tutorialTarget(.palette, active: tutorial.step == .palette || tutorial.step == .legend)

            if showGenreLegend {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Genre.all) { genre in
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(genre.color)
                                    .frame(width: 16, height: 16)

                                Text(genre.japaneseName)
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

    private var listSheet: some View {
        VStack(spacing: 8) {
            HStack {
                Text("近くのお店 \(restaurants.count)件")
                    .font(.headline)
                Spacer()
                if !isListTutorial {
                    Button {
                        showsList = false
                    } label: {
                        Image(systemName: "xmark")
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("店舗一覧を閉じる")
                }
            }
            .padding(.horizontal)
            .padding(.top, 14)

            ScrollViewReader { scroll in
                restaurantList
                    .onChange(of: tutorialFavoriteID, initial: true) { _, id in
                        if let id { scroll.scrollTo(id, anchor: .center) }
                    }
            }
        }
        .overlayPreferenceValue(TutorialBounds.self) { anchors in
            if let step = tutorial.step, step == .favorite || step == .candidate {
                GeometryReader { geometry in
                    let viewport = anchors[.listViewport]?.first.map { geometry[$0] }
                    let buttons = anchors[step == .favorite ? .heart : .candidate] ?? []
                    let target = buttons.map { geometry[$0] }.first { viewport?.contains($0) == true }
                    TutorialSpotlight(step: step, target: target, finish: tutorial.finish) {
                        if step == .favorite { tutorial.advance(from: .favorite, to: .candidate) }
                        else { tutorial.advance(from: .candidate, to: .random) }
                    }
                }
            }
        }
        .presentationDetents(isListTutorial ? [Self.expandedList] : [Self.compactList, Self.expandedList],
                             selection: $listHeight)
        .presentationDragIndicator(isListTutorial ? .hidden : .visible)
        .presentationContentInteraction(.scrolls)
        .presentationBackgroundInteraction(isListTutorial ? .disabled : .enabled)
        .presentationBackground(Color.moguCanvas)
        .interactiveDismissDisabled(isListTutorial)
        .tint(.moguInk)
        .alert(item: issueBinding(inList: true), content: searchAlert)
        .sheet(item: $candidateRestaurant, onDismiss: {
            tutorial.advance(from: .selecting, to: .random)
        }) { restaurant in
            CandidateSelectionView(restaurant: restaurant)
                .safeAreaInset(edge: .bottom) {
                    if tutorial.step == .selecting { TutorialHint(step: .selecting, finish: tutorial.finish) }
                }
        }
    }

    private var restaurantList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(restaurants) { restaurant in
                    HStack(spacing: 8) {
                        Button {
                            open(.detail(restaurant))
                        } label: {
                            RestaurantRow(restaurant: restaurant, style: .home)
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

    private func focusOnRestaurant(_ restaurant: Restaurant) {

        let coordinate = CLLocationCoordinate2D(
            latitude: restaurant.lat,
            longitude: restaurant.lng
        )

        withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
            highlightedRestaurantID = restaurant.id
            if !isListTutorial { listHeight = Self.compactList }
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
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        lastSearchCenter = coordinate

        do {
            let result = try await HotPepperAPIService().fetchRestaurants(filters: filters, coordinate: coordinate)

            guard latestSearchID == requestID else { return }
            let searchLocation = CLLocation(
                latitude: latitude,
                longitude: longitude
            )
            let sortedRestaurants = result
                .map { (restaurant: $0, distance: $0.distance(from: searchLocation)) }
                .sorted { $0.distance < $1.distance }
                .map(\.restaurant)

            restaurants = sortedRestaurants
            searchIssue = sortedRestaurants.isEmpty && tutorial.step == nil ? .noResults : nil
            fitMapToRestaurants(sortedRestaurants)
        } catch {
            guard latestSearchID == requestID else { return }
            if tutorial.step == nil { searchIssue = (error as? SearchIssue) ?? .connection }
        }
    }

    private func fitMapToRestaurants(_ restaurants: [Restaurant]) {
        guard !restaurants.isEmpty,
              let center = mapCenter else { return }

        let centerLocation = CLLocation(
            latitude: center.latitude,
            longitude: center.longitude
        )

        let distances = restaurants.map { $0.distance(from: centerLocation) }.sorted()
        let maxDistance = distances.prefix(6).last ?? 0

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

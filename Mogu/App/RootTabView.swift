//
//  RootTabView.swift
//  Mogu
//
//  Created by cmStudent on 2026/11/14.
//

import SwiftUI
import MapKit

struct RootTabView: View {

    @Environment(\.dynamicTypeSize) private var systemTextSize
    @AppStorage("appTextSize") private var textSize: AppTextSize = .system
    private enum AppTab { case home, favorites, candidates, settings }
    @State private var selectedTab = AppTab.home
    @State private var homeSession = UUID()
    @StateObject private var tutorial = MoguTutorial()
    @State private var showTutorialCompletion = false
    @State private var randomAfterTutorial = false
    @State private var filters = SearchFilters()
    @State private var showSearchFilter = false
    @State private var restaurants: [Restaurant] = []
    @State private var randomRestaurant: Restaurant?
    @State private var currentCoordinate: CLLocationCoordinate2D?
    @State private var searchIssue: SearchIssue?
    @State private var isRandomLoading = false
    @StateObject private var favoritesStore = FavoritesStore()
    @StateObject private var candidateStore = CandidateStore()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                Group {
                    if showSearchFilter {
                        SearchFilterView(
                            tutorial: tutorial,
                            filters: $filters,
                            showSearchFilter: $showSearchFilter,
                            onRandom: {
                                if tutorial.step == .random {
                                    randomAfterTutorial = true
                                    tutorial.finish()
                                    return
                                }
                                Task {
                                    await pickRandomRestaurant()
                                }
                            }
                        )
                    } else {
                        HomeMapView(
                            tutorial: tutorial,
                            filters: $filters,
                            showSearchFilter: $showSearchFilter,
                            restaurants: $restaurants,
                            currentCoordinate: $currentCoordinate
                        )
                    }
                }
                .toolbar(tutorial.step == nil ? .automatic : .hidden, for: .tabBar)
                .navigationDestination(
                    isPresented: Binding(
                        get: { randomRestaurant != nil },
                        set: { if !$0 { randomRestaurant = nil } }
                    )
                ) {
                    if let restaurant = randomRestaurant {
                        RandomRestaurantView(
                            restaurant: restaurant,
                            onRetry: {
                                Task {
                                    await pickRandomRestaurant()
                                }
                            }
                        )
                    }
                }
            }
            .id(homeSession)
            .tag(AppTab.home)
            .tabItem {
                Label("ホーム", systemImage: "house")
            }

            FavoritesView()
                .tag(AppTab.favorites)
                .tabItem {
                    Label("お気に入り", systemImage: "heart")
                }

            CandidateListsView()
                .tag(AppTab.candidates)
                .tabItem { Label("候補リスト", systemImage: "list.bullet") }

            SettingsView(textSize: $textSize) {
                randomRestaurant = nil
                showSearchFilter = false
                homeSession = UUID()
                tutorial.start()
                selectedTab = .home
            }
                .tag(AppTab.settings)
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
        }
        .onChange(of: tutorial.step) { previous, step in
            if step == .random { showSearchFilter = true }
            if previous == .random && step == nil { showTutorialCompletion = true }
        }
        .alert("チュートリアルが終了しました", isPresented: $showTutorialCompletion) {
            Button(randomAfterTutorial ? "お店を選ぶ" : "はじめる") {
                if randomAfterTutorial {
                    randomAfterTutorial = false
                    Task { await pickRandomRestaurant() }
                }
            }
        } message: {
            Text("一緒にお店を決めていきましょう！")
        }
        .alert(item: $searchIssue) { issue in
            issue.alert {
                randomRestaurant = nil
                showSearchFilter = true
            } retry: {
                Task { await pickRandomRestaurant() }
            }
        }
        .tint(.moguInk)
        .environmentObject(favoritesStore)
        .environmentObject(candidateStore)

        .overlay {
            if isRandomLoading {
                LoadingView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.regularMaterial)
            }
        }
        .dynamicTypeSize(textSize.displaySize(systemSize: systemTextSize))

    }

    private func pickRandomRestaurant() async {
        guard !isRandomLoading else { return }

        isRandomLoading = true
        defer { isRandomLoading = false }

        let coordinate: (latitude: Double, longitude: Double)

        switch filters.location {
        case .station(_, let latitude, let longitude):
            coordinate = (latitude, longitude)

        case .currentLocation, .unspecified:
            guard let currentCoordinate else {
                searchIssue = .location
                return
            }

            coordinate = (
                currentCoordinate.latitude,
                currentCoordinate.longitude
            )
        }

        guard let apiKey = HotPepperAPIService.apiKey else {
            searchIssue = .configuration
            return
        }

        do {
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
                name: filters.restaurantName
            )

            guard !results.isEmpty else {
                searchIssue = .noResults
                return
            }
            randomRestaurant = RestaurantRandomizer.pick(
                from: results,
                excluding: randomRestaurant?.id
            )

        } catch {
            searchIssue = .connection
        }
    }
}

#Preview {
    RootTabView()
}

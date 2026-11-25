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
                    //絞り込み画面
                    if showSearchFilter {
                        SearchFilterView(
                            tutorial: tutorial,
                            filters: $filters,
                            showSearchFilter: $showSearchFilter,
                            //ランダムボタン
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
                //チュートリアル中のタブバー
                .toolbar(tutorial.step == nil ? .automatic : .hidden, for: .tabBar)
                //おまかせ画面への遷移
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

        let coordinate: CLLocationCoordinate2D

        switch filters.location {
        case .station(_, let latitude, let longitude):
            coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        case .currentLocation, .unspecified:
            guard let currentCoordinate else {
                searchIssue = .location
                return
            }

            coordinate = currentCoordinate
        }

        do {
            let results = try await HotPepperAPIService().fetchRestaurants(filters: filters, coordinate: coordinate)

            guard !results.isEmpty else {
                searchIssue = .noResults
                return
            }
            randomRestaurant = RestaurantRandomizer.pick(
                from: results,
                excluding: randomRestaurant?.id
            )

        } catch {
            searchIssue = (error as? SearchIssue) ?? .connection
        }
    }
}

#Preview {
    RootTabView()
}

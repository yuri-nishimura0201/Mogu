//
//  RootTabView.swift
//  Mogu
//
//  Created by cmStudent on 2026/11/14.
//

import SwiftUI
import MapKit

struct RootTabView: View {

    @State private var filters = SearchFilters()
    @State private var showSearchFilter = false
    @State private var restaurants: [Restaurant] = []
    @State private var randomRestaurant: Restaurant?
    @State private var currentCoordinate: CLLocationCoordinate2D?
    @State private var isRandomLoading = false
    @StateObject private var favoritesStore = FavoritesStore()
    @StateObject private var candidateStore = CandidateStore()

    var body: some View {
        TabView {
            NavigationStack {
                Group {
                    if showSearchFilter {
                        SearchFilterView(
                            filters: $filters,
                            showSearchFilter: $showSearchFilter,
                            onRandom: {
                                Task {
                                    await pickRandomRestaurant()
                                }
                            }
                        )
                    } else {
                        HomeMapView(
                            filters: $filters,
                            showSearchFilter: $showSearchFilter,
                            restaurants: $restaurants,
                            currentCoordinate: $currentCoordinate
                        )
                    }
                }
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
            .tabItem {
                Label("ホーム", systemImage: "house")
            }

            FavoritesView()
                .tabItem {
                    Label("お気に入り", systemImage: "heart")
                }

            CandidateListsView()
                .tabItem { Label("候補リスト", systemImage: "list.bullet") }

            Text("設定画面")
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
        }
        .tint(.brown)
        .environmentObject(favoritesStore)
        .environmentObject(candidateStore)

        .overlay {
            if isRandomLoading {
                LoadingView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.regularMaterial)
            }
        }

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
                print("現在地を取得できていません")
                return
            }

            coordinate = (
                currentCoordinate.latitude,
                currentCoordinate.longitude
            )
        }

        guard let apiKey = Bundle.main.object(
            forInfoDictionaryKey: "HOTPEPPER_API_KEY"
        ) as? String,
              !apiKey.isEmpty,
              !apiKey.contains("$(") else {
            print("APIキーを読み込めませんでした")
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

            randomRestaurant = RestaurantRandomizer.pick(
                from: results,
                excluding: randomRestaurant?.id
            )

        } catch {
            print("ランダム検索エラー: \(error)")
        }
    }
}

#Preview {
    RootTabView()
}

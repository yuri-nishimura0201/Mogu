//
//  RootTabView.swift
//  Mogu
//
//  Created by cmStudent on 2026/11/14.
//

import SwiftUI

struct RootTabView: View {

    @State private var filters = SearchFilters()
    @State private var showSearchFilter = false
    @StateObject private var favoritesStore = FavoritesStore()
    @StateObject private var candidateStore = CandidateStore()

    var body: some View {
        TabView {
            NavigationStack {
                Group {
                    if showSearchFilter {
                        SearchFilterView(
                            filters: $filters,
                            showSearchFilter: $showSearchFilter
                        )
                    } else {
                        HomeMapView(
                            filters: $filters,
                            showSearchFilter: $showSearchFilter
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
        .environmentObject(candidateStore) // ← ここを追加！
    }
}
#Preview {
    RootTabView()
}

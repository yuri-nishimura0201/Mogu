
import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @State private var filters = SearchFilters()
    @State private var showSearchFilter = false
    @State private var randomRestaurant: Restaurant?
    @State private var showNoResultsAlert = false

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

            return matchesGenre && matchesBudget
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
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("お気に入り")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if showSearchFilter {
                        Button {
                            showSearchFilter = false
                        } label: {
                            Label("戻る", systemImage: "chevron.left")
                                .foregroundStyle(.brown)
                        }
                    }
                }

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
                    RandomRestaurantView(restaurant: restaurant)
                }
            }
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
}

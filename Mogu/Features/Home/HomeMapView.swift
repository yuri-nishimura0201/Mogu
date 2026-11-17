
import SwiftUI
import MapKit
import Combine



struct HomeMapView: View {
    
    @StateObject private var locationService = LocationService()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var restaurants: [Restaurant] = []
    @State private var mapCenter: CLLocationCoordinate2D?
    @State private var showSearchButton = false
    @State private var selectedRestaurant: Restaurant?
    @State private var isListExpanded = false
    @Binding var filters: SearchFilters
    @Binding var showSearchFilter: Bool
    
    var body: some View {
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
                            selectedRestaurant = restaurant
                        } label: {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(.brown)
                                .background(
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 28, height: 28)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            
            .onMapCameraChange(frequency: .onEnd) { context in
                mapCenter = context.region.center
                showSearchButton = true
            }
            
            .onAppear {
                locationService.requestLocation()
            }

            .onReceive(locationService.$coordinate.compactMap { $0 }) {
                coordinate in
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
                .padding(.top, 16)
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

                    restaurantList
                }
                .frame(
                    height: isListExpanded ? 450 : 180,
                    alignment: .top
                )
                .frame(maxWidth: .infinity)
                .background(
                    Color(red: 1.0, green: 0.98, blue: 0.96),
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
                set: { if !$0 { selectedRestaurant = nil } }
            )
        ) {
            if let restaurant = selectedRestaurant {
                RestaurantDetailView(restaurant: restaurant)
            }
        }
        
        .overlay(alignment: .topTrailing) {
            Button {
                showSearchFilter = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .foregroundStyle(.brown)
                    .padding(12)
                    .background(.regularMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 16)
            .padding(.top, 12)
        }
    }
    
    
    private var restaurantList: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text("近くのお店 \(restaurants.count)件")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(restaurants) { restaurant in
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
                            .padding(.horizontal)
                            
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(.top, 16)
    }
    
    private func loadRestaurants(
        latitude: Double,
        longitude: Double
    ) async {
        guard let apiKey = Bundle.main.object(
            forInfoDictionaryKey: "HOTPEPPER_API_KEY"
        ) as? String,
              !apiKey.isEmpty,
              !apiKey.contains("$(") else {
            print("APIキーを読み込めませんでした")
            return
        }
        
        do {
            let result = try await HotPepperAPIService().fetchRestaurants(
                latitude: latitude,
                longitude: longitude,
                apiKey: apiKey,
                range: filters.range,
                genres: filters.selectedGenres,
                budget: filters.budget,
                openingHours: filters.openingHours,
                partyCapacity: filters.partyCapacity,
                partyOptions: filters.selectedPartyOptions,
                preferences: filters.selectedPreferences
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
                restaurants = sortedRestaurants
                fitMapToRestaurants(sortedRestaurants)
            }
        } catch {
            print("API通信エラー: \(error)")
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
        showSearchFilter: .constant(false)
    )
}

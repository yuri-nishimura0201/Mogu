
import SwiftUI
import MapKit
import Combine



struct HomeMapView: View {
    
    @StateObject private var locationService = LocationService()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var restaurants: [Restaurant] = []
    @State private var showRestaurantList = true
    @State private var mapCenter: CLLocationCoordinate2D?
    @State private var showSearchButton = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition) {
                ForEach(restaurants) { restaurant in
                    //                Annotation(
                    //                    restaurant.name,
                    //                    coordinate: CLLocationCoordinate2D(
                    //                        latitude: restaurant.lat,
                    //                        longitude: restaurant.lng
                    //                    )
                    //                )
                    //                {
                    //                    VStack(spacing: 4) {
                    //                        AsyncImage(
                    //                            url: URL(string: restaurant.photo.mobile.s)
                    //                        ) { image in
                    //                            image
                    //                                .resizable()
                    //                                .scaledToFill()
                    //                        } placeholder: {
                    //                            Image(systemName: "fork.knife")
                    //                                .foregroundStyle(.brown)
                    //                        }
                    //                        .frame(width: 60, height: 60)
                    //                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    //
                    //                        Text(restaurant.genre.name)
                    //                            .font(.caption2)
                    //                            .foregroundStyle(.secondary)
                    //                            .lineLimit(1)
                    //
                    //                        Text("営業時間を確認")
                    //                            .font(.caption2)
                    //                            .foregroundStyle(.secondary)
                    //
                    //                    }
                    //                    .padding(6)
                    //                    .frame(width: 130)
                    //                    .background(.regularMaterial)
                    //                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    //                    .shadow(radius: 3)
                    //                }
                    Marker(
                        restaurant.name,
                        coordinate: CLLocationCoordinate2D(
                            latitude: restaurant.lat,
                            longitude: restaurant.lng
                        )
                    )
                    .tint(.brown)
                }
            }
            
            .onMapCameraChange(frequency: .onEnd) { context in
                mapCenter = context.region.center
                showSearchButton = true
            }
            
            .onAppear {
                print("① HomeMapViewが表示された！")
                locationService.requestLocation()
            }
            .onReceive(locationService.$coordinate.compactMap { $0 }) {
                coordinate in
                print("② 現在地を取得した！")
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(
                            latitudeDelta: 0.01,
                            longitudeDelta: 0.01
                        )
                    )
                )
                
                print("③ API検索を開始する！")
                
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
                    
                    print("再検索地点：\(center.latitude), \(center.longitude)")
                    
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
            
        } //ZStack
        
        .sheet(isPresented: $showRestaurantList) {
            restaurantList
                .presentationDetents([.height(180), .medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
                .interactiveDismissDisabled()
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
                                    
                                    Text("\(restaurant.open)")
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
                apiKey: apiKey
            )
            
            await MainActor.run {
                restaurants = result
                fitMapToRestaurants(result)
            }
            print("取得した店舗数: \(result.count)")
            
            for restaurant in result {
                print("店舗名: \(restaurant.name)")
                
                print("営業時間: \(restaurant.open)")
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

        // 検索地点に近い6店舗を選ぶ
        let nearby = restaurants.sorted {
            CLLocation(latitude: $0.lat, longitude: $0.lng)
                .distance(from: centerLocation)
            <
            CLLocation(latitude: $1.lat, longitude: $1.lng)
                .distance(from: centerLocation)
        }
        .prefix(6)

        // 選んだ店舗までの最大距離
        let maxDistance = nearby.map {
            CLLocation(latitude: $0.lat, longitude: $0.lng)
                .distance(from: centerLocation)
        }.max() ?? 0

        // 必要な表示範囲を計算（少し余裕を持たせる）
        let desiredDelta = min(
            max(maxDistance * 2.8 / 111_000, 0.005),
            0.02
        )

        // 現在の表示範囲より狭くはしない
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
    HomeMapView()
}

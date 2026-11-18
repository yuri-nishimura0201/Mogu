import SwiftUI

struct RandomRestaurantView: View {
    let restaurant: Restaurant

    var body: some View {
        VStack(spacing: 20) {
            Text("今日はここにする？")
                .font(.title2)
                .bold()

            AsyncImage(url: URL(string: restaurant.photo.mobile.l)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .frame(height: 220)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Text(restaurant.name)
                .font(.title3)
                .bold()
                .multilineTextAlignment(.center)

            Text(restaurant.genre.name)
                .foregroundStyle(.secondary)

            Text(restaurant.budget.name)
                .foregroundStyle(.secondary)

            NavigationLink {
                RestaurantDetailView(restaurant: restaurant)
            } label: {
                Text("お店の詳細を見る")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.brown, in: RoundedRectangle(cornerRadius: 14))
            }

            Spacer()
        }
        .padding()
        .navigationTitle("ランダムで決める")
        .navigationBarTitleDisplayMode(.inline)
    }
}

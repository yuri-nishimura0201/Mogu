import SwiftUI

struct RandomRestaurantView: View {
    @Environment(\.dismiss) private var dismiss

    let restaurant: Restaurant
    let onRetry: () -> Void

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

            Button {
                onRetry()
            } label: {
                Label("もう一度選ぶ", systemImage: "shuffle")
                    .font(.headline)
                    .foregroundStyle(.brown)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        Color.brown.opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
            }

            Button {
                dismiss()
            } label: {
                Label("前に戻る", systemImage: "arrow.left")
                    .font(.headline)
                    .foregroundStyle(.brown)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.brown, lineWidth: 1)
                    }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("ランダムで決める")
        .navigationBarTitleDisplayMode(.inline)
    }
}

import SwiftUI

struct RestaurantRow: View {
    enum Style {
        case home, favorites, candidateList
    }

    let restaurant: Restaurant
    let style: Style

    private var photoSize: CGFloat { style == .candidateList ? 70 : 80 }

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: restaurant.photo.mobile.s)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "fork.knife")
                    .foregroundStyle(Color.moguInk)
            }
            .frame(width: photoSize, height: photoSize)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                if style == .home {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Genre.color(for: restaurant.genre.code), lineWidth: 4)
                }
            }
            .padding(.leading, style == .home ? 12 : 0)

            VStack(alignment: .leading, spacing: 5) {
                Text(restaurant.name)
                    .font(.subheadline)
                    .bold()
                    .lineLimit(style == .candidateList ? nil : 2)

                Group {
                    Text(restaurant.genre.name)
                    if style == .home {
                        Text("予算目安：\(restaurant.budget.name)")
                        Text(restaurant.open)
                            .lineLimit(2)
                    } else {
                        Text(restaurant.budget.name)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if style == .home { Spacer() }
        }
    }
}

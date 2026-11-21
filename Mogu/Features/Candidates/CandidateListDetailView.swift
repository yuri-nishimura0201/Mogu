
import SwiftUI

struct CandidateListDetailView: View {

    @EnvironmentObject private var candidateStore: CandidateStore

    let listID: UUID

    @State private var showRenameAlert = false
    @State private var randomRestaurant: Restaurant?
    @State private var editedName = ""

    private var candidateList: CandidateList? {
        candidateStore.lists.first { $0.id == listID }
    }

    private var shareText: String {
        guard let list = candidateList else {
            return ""
        }

        var text = "Mogu 候補リスト\n\(list.name)\n\n"

        for (index, restaurant) in list.restaurants.enumerated() {
            text += "\(index + 1). \(restaurant.name)\n"
            text += "予算：\(restaurant.budget.name)\n"
            text += "\(restaurant.urls.pc)\n\n"
        }

        return text
    }


    var body: some View {
        Group {
            if let list = candidateList {
                if list.restaurants.isEmpty {
                    ContentUnavailableView(
                        "店舗が登録されていません",
                        systemImage: "fork.knife",
                        description: Text("気になるお店を候補リストに追加してみよう")
                    )
                } else {
                    List {
                        Button {
                            randomRestaurant = RestaurantRandomizer.pick(from: list.restaurants)
                        } label: {
                            Label("このリストから1店選ぶ", systemImage: "shuffle")
                        }

                        ForEach(list.restaurants) { restaurant in
                            NavigationLink {
                                RestaurantDetailView(restaurant: restaurant)
                            } label: {
                                HStack(spacing: 12) {
                                    AsyncImage(
                                        url: URL(string: restaurant.photo.mobile.s)
                                    ) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Image(systemName: "fork.knife")
                                            .foregroundStyle(Color.moguInk)
                                    }
                                    .frame(width: 70, height: 70)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(restaurant.name)
                                            .font(.subheadline)
                                            .bold()

                                        Text(restaurant.genre.name)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        Text(restaurant.budget.name)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                let restaurant = list.restaurants[index]
                                candidateStore.removeRestaurant(
                                    id: restaurant.id,
                                    from: listID
                                )
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "リストが見つかりません",
                    systemImage: "exclamationmark.triangle"
                )
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { randomRestaurant != nil },
            set: { if !$0 { randomRestaurant = nil } }
        )) {
            if let restaurant = randomRestaurant, let list = candidateList {
                RandomRestaurantView(restaurant: restaurant) {
                    randomRestaurant = RestaurantRandomizer.pick(
                        from: list.restaurants, excluding: restaurant.id
                    )
                }
            }
        }
        .navigationTitle(candidateList?.name ?? "候補リスト")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    editedName = candidateList?.name ?? ""
                    showRenameAlert = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(Color.moguInk)
                }
                .disabled(candidateList == nil)

                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.moguInk)
                }
                .disabled(candidateList?.restaurants.isEmpty ?? true)
            }
        }

        .alert("リスト名を変更", isPresented: $showRenameAlert) {
            TextField("リスト名", text: $editedName)

            Button("保存") {
                let name = editedName.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

                if !name.isEmpty {
                    candidateStore.renameList(id: listID, name: name)
                }
            }

            Button("キャンセル", role: .cancel) {}
        }
    }
}

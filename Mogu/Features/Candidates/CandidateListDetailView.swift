
import SwiftUI

struct CandidateListDetailView: View {

    @EnvironmentObject private var candidateStore: CandidateStore

    let listID: UUID

    @State private var showRenameAlert = false
    @State private var editedName = ""

    private var candidateList: CandidateList? {
        candidateStore.lists.first { $0.id == listID }
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
                                            .foregroundStyle(.brown)
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
        .navigationTitle(candidateList?.name ?? "候補リスト")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editedName = candidateList?.name ?? ""
                    showRenameAlert = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(.brown)
                }
                .disabled(candidateList == nil)
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

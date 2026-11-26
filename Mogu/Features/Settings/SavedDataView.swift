import SwiftUI

struct SavedDataView: View {
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var candidates: CandidateStore
    @State private var selection: Deletion?

    //削除対象と表示ぶんをまとめて管理、ボタンの生成を共通化
    private enum Deletion: CaseIterable, Identifiable {
        case favorites, candidates, all
        var id: Self { self }

        var title: LocalizedStringKey {
            switch self {
            case .favorites: "お気に入りをすべて削除"
            case .candidates: "候補リストをすべて削除"
            case .all: "保存データをすべて削除"
            }
        }
    }

    var body: some View {
        Form {
            Section {
                ForEach(Deletion.allCases) { option in
                    Button(role: .destructive) {
                        selection = option
                    } label: { Text(option.title) }
                    .disabled(isEmpty(option))
                }
            } footer: {
                Text("文字サイズ・表示モードとチュートリアルの設定は保持されます。")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.moguCanvas)
        .navigationTitle("保存データの削除")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $selection) { option in
            Alert(title: Text(option.title),
                  message: Text("この操作は取り消せません。本当に削除しますか？"),
                  primaryButton: .destructive(Text("削除")) { delete(option) },
                  secondaryButton: .cancel(Text("キャンセル")))
        }
    }

    //データの削除は各Storeで
    private func delete(_ option: Deletion) {
        switch option {
        case .favorites: favorites.removeAll()
        case .candidates: candidates.removeAll()
        case .all:
            favorites.removeAll()
            candidates.removeAll()
        }
    }

    private func isEmpty(_ option: Deletion) -> Bool {
        let noFavorites = favorites.favoriteIDs.isEmpty && favorites.favoriteRestaurants.isEmpty
        switch option {
        case .favorites: return noFavorites
        case .candidates: return candidates.lists.isEmpty
        case .all: return noFavorites && candidates.lists.isEmpty
        }
    }
}

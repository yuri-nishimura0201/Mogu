import SwiftUI

struct CandidateSelectionView: View {
    @EnvironmentObject private var candidateStore: CandidateStore
    @Environment(\.dismiss) private var dismiss

    let restaurant: Restaurant
    @State private var selectedListIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Group {
                if candidateStore.lists.isEmpty {
                    ContentUnavailableView(
                        "候補リストがありません",
                        systemImage: "list.bullet",
                        description: Text("候補リストタブからリストを作成してください")
                    )
                } else {
                    List {
                        ForEach(candidateStore.lists) { list in
                            Button {
                                if selectedListIDs.contains(list.id) {
                                    selectedListIDs.remove(list.id)
                                } else {
                                    selectedListIDs.insert(list.id)
                                }
                            } label: {
                                HStack {
                                    Text(list.name)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    if selectedListIDs.contains(list.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.brown)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("候補リストに追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("追加") {
                        for listID in selectedListIDs {
                            candidateStore.addRestaurant(restaurant, to: listID)
                        }
                        dismiss()
                    }
                    .disabled(selectedListIDs.isEmpty)
                }
            }
        }
    }
}

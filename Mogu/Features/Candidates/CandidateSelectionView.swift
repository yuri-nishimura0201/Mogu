import SwiftUI

struct CandidateSelectionView: View {
    @EnvironmentObject private var candidateStore: CandidateStore
    @Environment(\.dismiss) private var dismiss

    let restaurant: Restaurant
    @State private var selectedListIDs: Set<UUID> = []

    @State private var showCreateList = false
    @State private var listName = ""

    var body: some View {
        NavigationStack {
            List {
                Button {
                    listName = ""
                    showCreateList = true
                } label: {
                    Label("新しいリストを作って追加", systemImage: "plus")
                }

                ForEach(candidateStore.lists) { list in
                    let alreadyAdded = list.restaurants.contains { $0.id == restaurant.id }
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

                            if alreadyAdded {
                                Text("追加済み").foregroundStyle(.secondary)
                            } else if selectedListIDs.contains(list.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.moguInk)
                            }
                        }
                    }
                    .disabled(alreadyAdded)
                }
            }
            .alert("新しい候補リスト", isPresented: $showCreateList) {
                TextField("リスト名", text: $listName)
                Button("作成して追加") {
                    let name = listName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    candidateStore.addList(name: name, restaurants: [restaurant])
                    addToSelectedLists()
                }
                .disabled(listName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("キャンセル", role: .cancel) {}
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
                        addToSelectedLists()
                    }
                    .disabled(selectedListIDs.isEmpty)
                }
            }
        }
    }

    private func addToSelectedLists() {
        for listID in selectedListIDs {
            candidateStore.addRestaurant(restaurant, to: listID)
        }
        dismiss()
    }
}


import SwiftUI

struct CandidateListsView: View {

    @EnvironmentObject private var candidateStore: CandidateStore

    @State private var showAddAlert = false
    @State private var newListName = ""
    @State private var listToDelete: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if candidateStore.lists.isEmpty {
                    ContentUnavailableView(
                        "候補リストはまだありません",
                        systemImage: "list.bullet",
                        description: Text("右上の＋からリストを作成してみよう")
                    )
                } else {
                    List {
                        ForEach(candidateStore.lists) { list in
                            HStack(spacing: 4) {

                                NavigationLink {
                                    CandidateListDetailView(listID: list.id)
                                } label: {
                                    HStack {
                                        Image(systemName: "list.bullet")
                                            .foregroundStyle(.brown)

                                        Text(list.name)

                                        Spacer()

                                        Text("\(list.restaurants.count)店舗")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Button {
                                    listToDelete = list.id
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                        .frame(width: 44, height: 44)
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("\(list.name)を削除")
                            }
                        }
                        .onDelete(perform: deleteLists)

                    }
                }
            }
            .navigationTitle("候補リスト")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newListName = ""
                        showAddAlert = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.brown)
                    }
                }
            }
            .alert("新しい候補リスト", isPresented: $showAddAlert) {
                TextField("リスト名", text: $newListName)

                Button("作成") {
                    let name = newListName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                    if !name.isEmpty {
                        candidateStore.addList(name: name)
                    }
                }

                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("リストの名前を入力してください")
            }
            .confirmationDialog(
                "候補リストを削除しますか？",
                isPresented: Binding(
                    get: { listToDelete != nil },
                    set: {
                        if !$0 {
                            listToDelete = nil
                        }
                    }
                ),
                titleVisibility: .visible,
                presenting: listToDelete
            ) { id in
                Button("削除", role: .destructive) {
                    candidateStore.deleteList(id: id)
                }

                Button("キャンセル", role: .cancel) {}
            } message: { _ in
                Text("削除した候補リストは元に戻せません。")
            }
        }
    }

    private func deleteLists(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        listToDelete = candidateStore.lists[index].id
    }
}

#Preview {
    CandidateListsView()
        .environmentObject(CandidateStore())
}

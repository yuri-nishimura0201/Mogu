
import SwiftUI

struct CandidateListsView: View {

    @EnvironmentObject private var candidateStore: CandidateStore

    @State private var showAddAlert = false
    @State private var newListName = ""

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
        }
    }

    private func deleteLists(at offsets: IndexSet) {
        for index in offsets {
            let list = candidateStore.lists[index]
            candidateStore.deleteList(id: list.id)
        }
    }
}

#Preview {
    CandidateListsView()
        .environmentObject(CandidateStore())
}

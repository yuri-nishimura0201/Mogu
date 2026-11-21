import SwiftUI

struct PartyFilterView: View {
    @Binding var filters: SearchFilters
    @Environment(\.dismiss) private var dismiss

    private let capacities = [
        ("指定なし", 0),
        ("10人以上", 10),
        ("20人以上", 20),
        ("30人以上", 30),
        ("50人以上", 50)
    ]

    private let options: [(name: String, option: PartyOption)] = [
        ("個室あり", .privateRoom),
        ("貸切可", .charter),
        ("コースあり", .course),
        ("飲み放題", .freeDrink),
        ("食べ放題", .freeFood),
        ("掘りごたつ", .horigotatsu)
    ]

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("宴会対応人数") {
                    Picker(
                        "人数",
                        selection: Binding(
                            get: { filters.partyCapacity ?? 0 },
                            set: { filters.partyCapacity = $0 == 0 ? nil : $0 }
                        )
                    ) {
                        ForEach(capacities, id: \.1) { capacity in
                            Text(capacity.0)
                                .tag(capacity.1)
                        }
                    }
                    .tint(.moguInk)
                }

                Section("設備・サービス") {
                    ForEach(options, id: \.option) { item in
                        Toggle(
                            item.name,
                            isOn: Binding(
                                get: {
                                    filters.selectedPartyOptions.contains(item.option)
                                },
                                set: { isOn in
                                    if isOn {
                                        filters.selectedPartyOptions.insert(item.option)
                                    } else {
                                        filters.selectedPartyOptions.remove(item.option)
                                    }
                                }
                            )
                        )
                        .tint(.moguInk)
                    }
                }
            }

            Button {
                dismiss()
            } label: {
                Text("完了")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        Color.moguFill,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
            }
            .padding()
        }
        .navigationTitle("人数・宴会")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PartyFilterView(filters: .constant(SearchFilters()))
    }
}

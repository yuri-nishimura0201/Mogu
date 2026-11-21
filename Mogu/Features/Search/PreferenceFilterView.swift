import SwiftUI

struct PreferenceFilterView: View {
    @Binding var filters: SearchFilters
    @Environment(\.dismiss) private var dismiss

    private let sections: [(title: String, options: [(name: String, option: PreferenceOption)])] = [
        ("決済・喫煙", [
            ("クレジットカード対応", .card),
            ("禁煙席あり", .nonSmoking)
        ]),
        ("設備・サービス", [
            ("Wi-Fiあり", .wifi),
            ("駐車場あり", .parking),
            ("バリアフリー", .barrierFree),
            ("英語メニューあり", .english)
        ]),
        ("利用シーン", [
            ("ペット同伴可", .pet),
            ("子ども連れOK", .child),
            ("夜景がきれい", .nightView),
            ("テラス・オープンエア", .openAir)
        ]),
        ("その他", [
            ("ワイン充実", .wine),
            ("日本酒充実", .sake),
            ("カラオケあり", .karaoke),
            ("座敷あり", .tatami)
        ])
    ]

    var body: some View {
        VStack(spacing: 0) {
            Form {
                ForEach(sections.indices, id: \.self) { index in
                    Section(sections[index].title) {
                        ForEach(sections[index].options.indices, id: \.self) { optionIndex in
                            let item = sections[index].options[optionIndex]

                            Toggle(
                                item.name,
                                isOn: Binding(
                                    get: {
                                        filters.selectedPreferences.contains(item.option)
                                    },
                                    set: { isOn in
                                        if isOn {
                                            filters.selectedPreferences.insert(item.option)
                                        } else {
                                            filters.selectedPreferences.remove(item.option)
                                        }
                                    }
                                )
                            )
                            .tint(.moguInk)
                        }
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
                    .background(Color.moguFill, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding()
        }
        .navigationTitle("こだわり条件")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PreferenceFilterView(filters: .constant(SearchFilters()))
    }
}

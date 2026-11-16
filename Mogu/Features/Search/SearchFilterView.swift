
import SwiftUI

struct SearchFilterView: View {

    @Binding var filters: SearchFilters
    @Binding var showSearchFilter: Bool

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                Text("検索・絞り込み")
                    .font(.headline)

                Spacer()

                Button("リセット") {
                    filters = SearchFilters()
                }
                .font(.caption)
                .foregroundStyle(.brown)
            }
            .padding()

            Divider()

            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Image(systemName: "location")
                        .foregroundStyle(.brown)
                        .frame(width: 24)

                    Text("エリア・現在地")
                        .font(.subheadline)

                    Spacer()

                    Picker("検索範囲", selection: $filters.range) {
                        ForEach(searchRanges, id: \.value) { range in
                            Text(range.name)
                                .tag(range.value)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(.brown)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Label("ジャンル", systemImage: "fork.knife")
                        .font(.subheadline)
                        .foregroundStyle(.brown)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(genres, id: \.code) { genre in
                                Button {
                                    if genre.code.isEmpty {
                                        filters.selectedGenres.removeAll()
                                    } else if filters.selectedGenres.contains(genre.code) {
                                        filters.selectedGenres.remove(genre.code)
                                    } else {
                                        filters.selectedGenres.insert(genre.code)
                                    }
                                } label: {

                                    Text(genre.name)
                                        .font(.subheadline)
                                        .foregroundStyle(
                                            isSelected(genre.code) ? Color.white : Color.brown
                                        )
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            isSelected(genre.code) ? Color.brown : Color.white,
                                            in: Capsule()
                                        )

                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }

                    Divider()
                }
                .padding(.vertical, 14)

                HStack(spacing: 14) {
                    Image(systemName: "yensign.circle")
                        .foregroundStyle(.brown)
                        .frame(width: 24)

                    Text("予算")
                        .font(.subheadline)

                    Spacer()

                    Picker(
                        "予算",
                        selection: Binding(
                            get: { filters.budget ?? "" },
                            set: { filters.budget = $0.isEmpty ? nil : $0 }
                        )
                    ) {
                        ForEach(budgets, id: \.code) { budget in
                            Text(budget.name)
                                .tag(budget.code)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(.brown)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                Divider()

                filterRow(
                    title: "営業時間",
                    value: "指定なし",
                    icon: "clock"
                )

                filterRow(
                    title: "人数・宴会",
                    value: "指定なし",
                    icon: "person.2"
                )

                filterRow(
                    title: "決済方法",
                    value: "すべて",
                    icon: "creditcard"
                )

                filterRow(
                    title: "こだわり条件",
                    value: "指定なし",
                    icon: "slider.horizontal.3"
                )
            }

            Spacer()

            Button {
                showSearchFilter = false
            } label: {
                Text("マップで見る")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        .brown,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
            }
            .padding()
        }
        .background(Color(red: 1.0, green: 0.98, blue: 0.96))
    }

    private func isSelected(_ code: String) -> Bool {
        if code.isEmpty {
            return filters.selectedGenres.isEmpty
        }

        return filters.selectedGenres.contains(code)
    }

    private let searchRanges: [(name: String, value: Int)] = [
        ("300m以内", 1),
        ("500m以内", 2),
        ("1km以内", 3),
        ("2km以内", 4),
        ("3km以内", 5)
    ]

    private let budgets: [(name: String, code: String)] = [
        ("指定なし", ""),
        ("～500円", "B009"),
        ("501～1000円", "B010"),
        ("1001～1500円", "B011"),
        ("1501～2000円", "B001"),
        ("2001～3000円", "B002"),
        ("3001～4000円", "B003"),
        ("4001～5000円", "B008"),
        ("5001～7000円", "B004"),
        ("7001～10000円", "B005"),
        ("10001～15000円", "B006"),
        ("15001～20000円", "B012"),
        ("20001～30000円", "B013"),
        ("30001円～", "B014")
    ]


    private let genres: [(name: String, code: String)] = [
        ("すべて", ""),
        ("居酒屋", "G001"),
        ("ダイニングバー・バル", "G002"),
        ("創作料理", "G003"),
        ("和食", "G004"),
        ("洋食", "G005"),
        ("イタリアン・フレンチ", "G006"),
        ("中華", "G007"),
        ("焼肉・ホルモン", "G008"),
        ("アジア・エスニック料理", "G009"),
        ("各国料理", "G010"),
        ("カラオケ・パーティ", "G011"),
        ("バー・カクテル", "G012"),
        ("ラーメン", "G013"),
        ("カフェ・スイーツ", "G014"),
        ("その他グルメ", "G015"),
        ("お好み焼き・もんじゃ", "G016"),
        ("韓国料理", "G017")
    ]

    private func filterRow(
        title: String,
        value: String,
        icon: String
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(.brown)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 18)
        .overlay(alignment: .bottom) {
            Divider()
                .padding(.leading, 50)
        }
    }
}

#Preview {
    SearchFilterView(
        filters: .constant(SearchFilters()),
        showSearchFilter: .constant(true)
    )
}

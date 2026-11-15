
import SwiftUI


struct SearchFilterView: View {

    @Binding var selectedGenre: String
    @Binding var showSearchFilter: Bool

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                Text("検索・絞り込み")
                    .font(.headline)

                Spacer()

                Button("リセット") {
                    selectedGenre = ""
                }
                .font(.caption)
                .foregroundStyle(.brown)
            }
            .padding()

            Divider()

            VStack(spacing: 0) {

                filterRow(
                    title: "エリア・現在地",
                    value: "現在地から1km",
                    icon: "location"
                )


                VStack(alignment: .leading, spacing: 12) {

                    Label("ジャンル", systemImage: "fork.knife")
                        .font(.subheadline)
                        .foregroundStyle(.brown)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(genres, id: \.code) { genre in
                                Button {
                                    selectedGenre = genre.code
                                } label: {
                                    Text(genre.name)
                                        .font(.subheadline)
                                        .foregroundStyle(
                                            selectedGenre == genre.code
                                                ? .white
                                                : .brown
                                        )
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            selectedGenre == genre.code
                                                ? Color.brown
                                                : Color.white,
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


                filterRow(
                    title: "予算",
                    value: "指定なし",
                    icon: "yensign.circle"
                )

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
        selectedGenre: .constant(""),
        showSearchFilter: .constant(true)
    )
}

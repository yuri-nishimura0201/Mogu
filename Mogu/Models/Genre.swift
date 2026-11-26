import SwiftUI

struct Genre: Identifiable {
    let code: String
    let japaneseName: String
    let englishName: String
    let color: Color
    var id: String { code }

    private static let otherColor = rgb(164, 185, 178)

    static let all: [Genre] = [
        Genre(code: "G001", japaneseName: "居酒屋", englishName: "Izakaya", color: rgb(255, 181, 111)),
        Genre(code: "G002", japaneseName: "ダイニングバー・バル", englishName: "Dining bars & bistros", color: rgb(163, 160, 233)),
        Genre(code: "G003", japaneseName: "創作料理", englishName: "Creative cuisine", color: rgb(192, 153, 233)),
        Genre(code: "G004", japaneseName: "和食", englishName: "Japanese", color: rgb(145, 206, 136)),
        Genre(code: "G005", japaneseName: "洋食", englishName: "Western-style Japanese", color: rgb(245, 211, 93)),
        Genre(code: "G006", japaneseName: "イタリアン・フレンチ", englishName: "Italian & French", color: rgb(245, 142, 166)),
        Genre(code: "G007", japaneseName: "中華", englishName: "Chinese", color: rgb(240, 141, 111)),
        Genre(code: "G008", japaneseName: "焼肉・ホルモン", englishName: "Yakiniku & offal", color: rgb(233, 118, 130)),
        Genre(code: "G009", japaneseName: "アジア・エスニック料理", englishName: "Asian cuisine", color: rgb(103, 205, 189)),
        Genre(code: "G010", japaneseName: "各国料理", englishName: "International", color: rgb(134, 173, 238)),
        Genre(code: "G011", japaneseName: "カラオケ・パーティ", englishName: "Karaoke & parties", color: rgb(198, 127, 203)),
        Genre(code: "G012", japaneseName: "バー・カクテル", englishName: "Bars & cocktails", color: rgb(138, 138, 205)),
        Genre(code: "G013", japaneseName: "ラーメン", englishName: "Ramen", color: rgb(233, 162, 76)),
        Genre(code: "G014", japaneseName: "カフェ・スイーツ", englishName: "Cafés & desserts", color: rgb(235, 164, 200)),
        Genre(code: "G015", japaneseName: "その他グルメ", englishName: "Other food", color: otherColor),
        Genre(code: "G016", japaneseName: "お好み焼き・もんじゃ", englishName: "Okonomiyaki & monjayaki", color: rgb(216, 167, 123)),
        Genre(code: "G017", japaneseName: "韓国料理", englishName: "Korean", color: rgb(235, 125, 176))
    ]

    static func color(for code: String?) -> Color {
        all.first { $0.code == code }?.color ?? otherColor
    }

    // RGB値で色を指定できるようにSwiftUI用の変換処理を共通化する
    private static func rgb(_ red: Double, _ green: Double, _ blue: Double) -> Color {
        Color(red: red / 255, green: green / 255, blue: blue / 255)
    }
}

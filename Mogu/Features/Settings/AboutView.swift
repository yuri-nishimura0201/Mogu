import SwiftUI

struct AboutView: View {
    var body: some View {
        Form {
            Section {
                Text("Mogu").font(.title.bold()).foregroundStyle(Color.moguInk)
                Text("近くのお店を地図で探して、気になるお店を保存。その日の一軒を選べるアプリです。")
            }
            Section("アプリ情報") {
                LabeledContent("バージョン", value: bundleValue("CFBundleShortVersionString"))
                LabeledContent("ビルド番号", value: bundleValue("CFBundleVersion"))
                LabeledContent("使用技術") {
                    Text("SwiftUI・MapKit・Core Location・Hot PepperグルメAPI")
                        .multilineTextAlignment(.trailing)
                }
            }
            Section("店舗情報・写真の提供元") {
                if let url = URL(string: "https://webservice.recruit.co.jp/") {
                    Link(destination: url) {
                        Text(verbatim: "Powered by ホットペッパーグルメ Webサービス")
                    }
                }
                Text(verbatim: "画像提供：ホットペッパー グルメ")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.moguCanvas)
        .navigationTitle("アプリについて")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bundleValue(_ key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "—"
    }
}

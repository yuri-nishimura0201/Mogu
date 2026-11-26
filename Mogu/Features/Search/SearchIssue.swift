import SwiftUI

//検索時のエラーと対処方法を一元管理。各Viewでの重複実装を回避
enum SearchIssue: String, Error, Identifiable {
    case noResults, location, connection, configuration

    var id: Self { self }

    func alert(changeFilters: @escaping () -> Void, retry: @escaping () -> Void) -> Alert {
        let title: String
        let action: Alert.Button
        switch self {
        case .noResults:
            title = "条件に合うお店がありません"
            action = .default(Text("条件を変更"), action: changeFilters)
        case .location:
            title = "現在地を取得できませんでした"
            action = .default(Text("駅名で探す"), action: changeFilters)
        case .connection:
            title = "お店の情報を取得できませんでした"
            action = .default(Text("再試行"), action: retry)
        case .configuration:
            return Alert(title: Text("検索に必要なAPIキーが設定されていません"))
        }
        return Alert(title: Text(title), primaryButton: action, secondaryButton: .cancel(Text("閉じる")))
    }
}

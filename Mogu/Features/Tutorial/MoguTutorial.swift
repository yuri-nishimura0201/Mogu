import SwiftUI
import Combine

enum TutorialStep {
    case palette, legend, pin, detail, filter, editing, favorite, candidate, selecting, random

    var number: Int {
        switch self {
        case .palette, .legend: return 1
        case .pin, .detail: return 2
        case .filter, .editing: return 3
        case .favorite: return 4
        case .candidate, .selecting: return 5
        case .random: return 6
        }
    }

    var message: String {
        switch self {
        case .palette: return "矢印が指すボタンを押して進んでください。まずは左上のパレットで、ピンの色の意味を確認しましょう。"
        case .legend: return "パレットをもう一度押すと閉じます。"
        case .pin: return "ピンを押すと店舗の詳細が開きます。"
        case .detail: return "地図に戻ると案内が続きます。"
        case .filter: return "場所や予算でお店を絞り込めます。"
        case .editing: return "「マップで見る」で検索結果を表示します。"
        case .favorite: return "ハートでお気に入りに保存できます。"
        case .candidate: return "お店を候補リストにまとめられます。リストを開くと、右上のボタンから共有できます。"
        case .selecting: return "リストを作成、選択ができます。"
        case .random: return "検索結果から1店をランダムに選びます。"
        }
    }
}

final class MoguTutorial: ObservableObject {
    @Published private(set) var step: TutorialStep?
    // 途中でアプリを閉じた場合も、次回は設定から再開する。
    @AppStorage("moguTutorialStatus") private var status = "new"

    var isFirstLaunch: Bool { status == "new" }

    func startIfNeeded() {
        if isFirstLaunch { start() }
    }

    func start() {
        status = "started"
        step = .palette
    }

    //想定した状態になったら次に進む
    func advance(from expected: TutorialStep, to next: TutorialStep) {
        if step == expected { step = next }
    }

    func finish() {
        status = "finished"
        step = nil
    }
}

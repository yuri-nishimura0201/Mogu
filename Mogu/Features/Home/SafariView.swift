
import SwiftUI
import SafariServices

//UIkitのsafari画面をSwiftUIで使えるようにする
struct SafariView: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(
        context: Context
    ) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    //URLの更新は不要のため更新処理はしない
    func updateUIViewController(
        _ uiViewController: SFSafariViewController,
        context: Context
    ) {}
}

import SwiftUI
import CoreLocation

enum AppTextSize: String, CaseIterable {
    case system = "端末設定に合わせる"
    case standard = "標準"
    case large = "大きめ"
    case extraLarge = "さらに大きめ"

    var title: String {
        self == .system ? "iPhoneの設定に合わせる" : rawValue
    }

    func displaySize(systemSize: DynamicTypeSize) -> DynamicTypeSize {
        // アクセシビリティ用の文字サイズを選んでいる場合は端末設定を優先する。
        if systemSize.isAccessibilitySize { return systemSize }
        switch self {
        case .system: return systemSize
        case .standard: return .large
        case .large: return .xLarge
        case .extraLarge: return .xxLarge
        }
    }
}

enum AppAppearance: String, CaseIterable {
    case system, light, dark

    var title: LocalizedStringKey {
        switch self {
        case .system: "iPhoneの設定に合わせる"
        case .light: "ライトモード"
        case .dark: "ダークモード"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

struct SettingsView: View {
    @Binding var textSize: AppTextSize
    let replayTutorial: () -> Void
    @AppStorage("appAppearance") private var appearance: AppAppearance = .system
    @Environment(\.scenePhase) private var scenePhase
    @State private var authorization = CLAuthorizationStatus.notDetermined
    @State private var showSettingsError = false

    private var locationStatus: LocalizedStringKey {
        switch authorization {
        case .notDetermined: "未設定"
        case .restricted: "制限中"
        case .denied: "許可しない"
        case .authorizedWhenInUse: "使用中のみ許可"
        case .authorizedAlways: "常に許可"
        @unknown default: "不明"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("表示") {
                    Picker(selection: $textSize) {
                        ForEach(AppTextSize.allCases, id: \.self) { size in
                            Text(size.title).tag(size)
                        }
                    } label: { Label("文字の大きさ", systemImage: "textformat.size") }
                    Picker(selection: $appearance) {
                        ForEach(AppAppearance.allCases, id: \.self) { mode in
                            Text(mode.title).tag(mode)
                        }
                    } label: { Label("表示モード", systemImage: "circle.lefthalf.filled") }
                }
                .pickerStyle(.navigationLink)

                Section {
                    Button(action: replayTutorial) {
                        Label("チュートリアルをもう一度見る", systemImage: "play.circle")
                    }
                    Button(action: openLocationSettings) {
                        LabeledContent {
                            Text(locationStatus)
                        } label: {
                            Label("位置情報の設定", systemImage: "location")
                        }
                    }
                } header: {
                    Text("アプリの利用")
                } footer: {
                    if authorization == .denied {
                        Text("位置情報は、iPhoneの「設定」→「アプリ」→「Mogu」で変更できます。")
                    }
                }

                Section("データと情報") {
                    NavigationLink {
                        SavedDataView()
                    } label: { Label("保存データの削除", systemImage: "trash") }
                    NavigationLink {
                        AboutView()
                    } label: { Label("アプリについて", systemImage: "info.circle") }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.moguCanvas)
            .navigationTitle("設定")
            .onAppear { refreshAuthorization() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { refreshAuthorization() }
            }
            .alert("設定を開けませんでした", isPresented: $showSettingsError) {
                Button("閉じる") {}
            } message: {
                Text("iPhoneの「設定」から「アプリ」→「Mogu」を開いてください。")
            }
        }
    }

    private func refreshAuthorization() {
        authorization = CLLocationManager().authorizationStatus
    }

    private func openLocationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            showSettingsError = true
            return
        }
        UIApplication.shared.open(url) { opened in showSettingsError = !opened }
    }
}

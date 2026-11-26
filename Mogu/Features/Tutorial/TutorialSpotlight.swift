import SwiftUI

enum TutorialTarget: Hashable {
    case palette, legend, filter, heart, candidate, listViewport, random
}

struct TutorialBounds: PreferenceKey {
    static let defaultValue: [TutorialTarget: [Anchor<CGRect>]] = [:]

    static func reduce(value: inout [TutorialTarget: [Anchor<CGRect>]], nextValue: () -> [TutorialTarget: [Anchor<CGRect>]]) {
        //複数のviewから取得した位置情報を対象ごとにまとめる
        for (target, anchors) in nextValue() {
            value[target, default: []].append(contentsOf: anchors)
        }
    }
}

extension View {
    func tutorialTarget(_ target: TutorialTarget, active: Bool) -> some View {
        transformAnchorPreference(key: TutorialBounds.self, value: .bounds) { targets, anchor in
            if active { targets[target, default: []].append(anchor) }
        }
    }
}

struct TutorialHint: View {
    let step: TutorialStep
    let finish: () -> Void
    var skipMissing: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(step.number) / 6")
                    .font(.subheadline.bold())
                    .accessibilityLabel("ステップ \(step.number)、全6ステップ")
                Spacer()
                Button("終了", action: finish)
                    .font(.subheadline)
                    .frame(minHeight: 44)
            }
            .foregroundStyle(Color.moguInk)

            Text(step.message)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            if let skipMissing {
                Button("このステップを飛ばす", action: skipMissing)
                    .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 4)
        .padding(.bottom, 16)
        .frame(maxWidth: 440, alignment: .leading)
        .background(Color.moguCanvas, in: RoundedRectangle(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).stroke(Color.moguInk.opacity(0.25)) }
        .shadow(color: .black.opacity(0.15), radius: 5, y: 2)
        .tint(.moguInk)
        .padding(8)
        .frame(maxWidth: .infinity)
    }
}

struct TutorialArrow: View {
    static let diameter: CGFloat = 44
    static let gap: CGFloat = 14

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let pointsDown: Bool

    var body: some View {
        Image(systemName: pointsDown ? "arrow.down" : "arrow.up")
            .font(.system(size: 28, weight: .bold))
            .foregroundStyle(Color.moguFill)
            .frame(width: Self.diameter, height: Self.diameter)
            .background(.white, in: Circle())
            .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
        //端末のアクセシビリティ設定に合わせてアニメーションを停止する
            .phaseAnimator(reduceMotion ? [false] : [false, true]) { arrow, near in
                let distanceTowardButton: CGFloat = pointsDown ? 10 : -10
                arrow.offset(y: near ? distanceTowardButton : 0)
            } animation: { near in
                near ? .easeOut(duration: 0.32) : .easeInOut(duration: 0.55)
            }
        //矢印がボタン操作を妨げないようにする
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct TutorialSpotlight: View {
    let step: TutorialStep
    let target: CGRect?
    var arrowTarget: CGRect? = nil
    let finish: () -> Void
    var skipMissing: (() -> Void)?

    var body: some View {
        GeometryReader { geometry in
            let bounds = CGRect(origin: .zero, size: geometry.size)
            let hole = target?.insetBy(dx: -4, dy: -4).intersection(bounds)
            //画面全体と操作対象の輪郭を定義
            let mask = Path { path in
                path.addRect(CGRect(x: -geometry.safeAreaInsets.leading, y: -geometry.safeAreaInsets.top,
                                    width: bounds.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing,
                                    height: bounds.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom))
                if let hole, !hole.isNull {
                    path.addRoundedRect(in: hole, cornerSize: CGSize(width: 14, height: 14))
                }
            }
            //操作対象だけをくり抜いてそれ以外は暗くしてタップできなくする
            mask.fill(.black.opacity(0.52), style: FillStyle(eoFill: true))
                .contentShape(mask, eoFill: true)
                .onTapGesture {}
                .accessibilityHidden(true)

            if let button = arrowTarget ?? target, bounds.intersects(button) {
                let radius = TutorialArrow.diameter / 2
                let distance = radius + TutorialArrow.gap
                //対象の上側にスペースがない場合下に矢印を配置
                let pointsDown = button.minY >= TutorialArrow.diameter + TutorialArrow.gap
                TutorialArrow(pointsDown: pointsDown)
                    .position(x: min(max(radius, button.midX), bounds.width - radius),
                              y: pointsDown ? button.minY - distance : button.maxY + distance)
            }

            //対象の上下で空き領域を比較し、説明カードの表示位置を決める
            let above = hole?.minY ?? 0
            let below = bounds.height - (hole?.maxY ?? 0)
            let useBottom = below >= above
            let availableHeight = max(1, useBottom ? below : above)
            //文字サイズ変更などで説明が収まらない場合スクロール表示に切り替えられる
            ViewThatFits(in: .vertical) {
                card.fixedSize(horizontal: false, vertical: true)
                ScrollView { card }
            }
            .frame(maxWidth: .infinity, maxHeight: availableHeight,
                   alignment: useBottom ? .bottom : .top)
            .frame(maxWidth: .infinity, maxHeight: .infinity,
                   alignment: useBottom ? .bottom : .top)
        }
    }

    private var card: some View {
        let canSkipStep = target == nil && [.pin, .favorite, .candidate].contains(step)
        return TutorialHint(step: step, finish: finish, skipMissing: canSkipStep ? skipMissing : nil)
    }
}

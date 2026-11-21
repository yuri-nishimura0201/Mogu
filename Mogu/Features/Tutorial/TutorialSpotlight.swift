import SwiftUI

enum TutorialTarget: Hashable {
    case palette, legend, filter, heart, candidate, listViewport, random
}

struct TutorialBounds: PreferenceKey {
    static let defaultValue: [TutorialTarget: [Anchor<CGRect>]] = [:]

    static func reduce(value: inout [TutorialTarget: [Anchor<CGRect>]], nextValue: () -> [TutorialTarget: [Anchor<CGRect>]]) {
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
                Button(step == .random ? "終了" : "スキップ", action: finish)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let pointsDown: Bool

    var body: some View {
        Image(systemName: pointsDown ? "arrow.down" : "arrow.up")
            .font(.system(size: 19, weight: .bold))
            .foregroundStyle(Color.moguFill)
            .frame(width: 32, height: 32)
            .background(.white, in: Circle())
            .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
            .phaseAnimator(reduceMotion ? [false] : [false, true]) { arrow, near in
                arrow.offset(y: near ? (pointsDown ? 5 : -5) : 0)
            } animation: { _ in .easeInOut(duration: 0.55) }
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
            let mask = Path { path in
                path.addRect(CGRect(x: -geometry.safeAreaInsets.leading, y: -geometry.safeAreaInsets.top,
                                    width: bounds.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing,
                                    height: bounds.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom))
                if let hole, !hole.isNull {
                    path.addRoundedRect(in: hole, cornerSize: CGSize(width: 14, height: 14))
                }
            }
            mask.fill(.black.opacity(0.52), style: FillStyle(eoFill: true))
                .contentShape(mask, eoFill: true)
                .onTapGesture {}
                .accessibilityHidden(true)

            if let button = arrowTarget ?? target, bounds.intersects(button) {
                let pointsDown = button.minY >= 44
                TutorialArrow(pointsDown: pointsDown)
                    .position(x: min(max(16, button.midX), bounds.width - 16),
                              y: pointsDown ? button.minY - 26 : button.maxY + 26)
            }

            let above = hole?.minY ?? 0
            let below = bounds.height - (hole?.maxY ?? 0)
            let useBottom = below >= above
            let availableHeight = max(1, useBottom ? below : above)
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

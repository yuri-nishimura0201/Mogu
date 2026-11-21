
import SwiftUI

struct SplashView: View {

    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var showContent = false
    @State private var showSymbol = false

    private let brown = Color(red: 0.44, green: 0.27, blue: 0.16)
    private let beige = Color(red: 1.0, green: 0.96, blue: 0.91)
    private let pink = Color(red: 0.96, green: 0.65, blue: 0.67)
    private let yellow = Color(red: 1.0, green: 0.83, blue: 0.48)
    private let mint = Color(red: 0.65, green: 0.85, blue: 0.83)

    var body: some View {

        ZStack {

            beige.ignoresSafeArea()

            VStack(spacing: 16) {

                ZStack(alignment: .topTrailing) {

                    Image(systemName: "fork.knife")
                        .font(.system(size: 70))
                        .foregroundStyle(brown)
                        .scaleEffect(showSymbol ? 1.0 : 0.5)

                    Image(systemName: "sparkles")
                        .font(.system(size: 25))
                        .foregroundStyle(yellow)
                        .offset(x: 30, y: -20)
                }
                .frame(width: 130, height: 130)

                Text("Mogu")
                    .font(.system(
                        size: 56,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundStyle(brown)

                HStack(spacing: 0) {
                    Text("いっしょにお店探し")
                        .foregroundStyle(brown)

                    Text("♪")
                        .foregroundStyle(pink)
                }
                .font(.system(size: 17, weight: .medium))

                HStack(spacing: 8) {

                    Circle().fill(pink)
                    Circle().fill(yellow)
                    Circle().fill(mint)
                }
                .frame(width: 50, height: 10)
                .padding(.top, 10)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 15)
        }
        .task {

            if reduceMotion {
                showContent = true
                showSymbol = true
            } else {
                withAnimation(.easeOut(duration: 0.5)) {
                    showContent = true
                }

                withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.15)) {
                    showSymbol = true
                }
            }

            try? await Task.sleep(for: .seconds(reduceMotion ? 0.3 : 1.9))
            guard !Task.isCancelled else { return }
            onFinish()
        }
    }
}

#Preview {
    SplashView(onFinish: {})
}

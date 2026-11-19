import SwiftUI

struct LoadingView: View {
    @State private var isRotating = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife")
                .font(.system(size: 50))
                .foregroundStyle(.brown)
                .rotation3DEffect(
                    .degrees(isRotating ? 360 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                .animation(
                    .linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: isRotating
                )

            Text("おいしいお店を探しています…")
                .font(.headline)
                .foregroundStyle(.brown)
        }
        .padding(30)
        .onAppear {
            isRotating = true
        }
    }
}

#Preview {
    LoadingView()
}

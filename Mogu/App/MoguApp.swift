
//
//  MoguApp.swift
//  Mogu
//
//  Created by cmStudent on 2026/11/14.
//

import SwiftUI

@main
struct MoguApp: App {

    @AppStorage("appAppearance")
    private var appearance: AppAppearance = .system

    @State private var showSplash = true

    var body: some Scene {

        WindowGroup {

            ZStack {

                if showSplash {

                    SplashView {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)

                } else {

                    RootTabView()
                        .transition(.opacity)
                }
            }
            .preferredColorScheme(appearance.colorScheme)
        }
    }
}

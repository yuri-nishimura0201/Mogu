//
//  RootTabView.swift
//  Mogu
//
//  Created by cmStudent on 2026/11/14.
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView{
            NavigationStack {
                HomeMapView()
            }
            .tabItem {
                Label("ホーム", systemImage: "house")
            }
            
            Text("お気に入り画面")
                .tabItem {
                    Label("お気に入り", systemImage: "heart")
                }
            
            Text("共有画面")
                          .tabItem {
                              Label("共有", systemImage: "person.2")
                          }
            
            Text("設定画面")
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
        }
        .tint(.brown)
    }
}

#Preview {
    RootTabView()
}

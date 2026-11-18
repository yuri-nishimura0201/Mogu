//
//  RestaurantDetailView.swift
//  Mogu
//
//  Created by cmStudent on 2026/11/15.
//


import SwiftUI

struct RestaurantDetailView: View {

    @EnvironmentObject private var candidateStore: CandidateStore

    let restaurant: Restaurant

    @State private var showSafari = false
    @State private var candidateMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                AsyncImage(
                    url: URL(string: restaurant.photo.mobile.l)
                ) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "fork.knife")
                        .foregroundStyle(.brown)
                }
                .frame(height: 230)
                .frame(maxWidth: .infinity)
                .clipped()

                VStack(alignment: .leading, spacing: 16) {

                    Text(restaurant.name)
                        .font(.title2)
                        .bold()

                    Text(restaurant.genre.name)
                        .foregroundStyle(.secondary)

                    Divider()

                    VStack(alignment: .leading, spacing: 5) {
                        Label("予算目安", systemImage: "yensign.circle")
                            .font(.headline)

                        Text(restaurant.budget.name)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 5) {
                        Label("営業時間", systemImage: "clock")
                            .font(.headline)

                        Text(restaurant.open)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 5) {
                        Label("住所", systemImage: "mappin.and.ellipse")
                            .font(.headline)

                        Text(restaurant.address)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Label("アクセス", systemImage: "figure.walk")
                            .font(.headline)

                        Text(restaurant.access)
                    }

                    Divider()

                    if URL(string: restaurant.urls.pc) != nil {
                        Button {
                            showSafari = true
                        } label: {
                            Label(
                                "メニュー・店舗情報・予約ページはこちら",
                                systemImage: "book.pages"
                            )
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                .brown,
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if candidateStore.lists.isEmpty {
                        Button("候補リストを作成してください") {}
                            .disabled(true)
                    } else {
                        ForEach(candidateStore.lists) { list in
                            Button(list.name) {
                                let wasAdded = candidateStore.addRestaurant(
                                    restaurant,
                                    to: list.id
                                )
                                candidateMessage = wasAdded
                                    ? "「\(list.name)」に追加しました"
                                    : "「\(list.name)」には追加済みです"
                            }
                        }
                    }
                } label: {
                    Image(systemName: "list.bullet.badge.plus")
                        .foregroundStyle(.brown)
                }
            }
        }
        .sheet(isPresented: $showSafari) {
            if let url = URL(string: restaurant.urls.pc) {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
        .alert(
            "候補リスト",
            isPresented: Binding(
                get: { candidateMessage != nil },
                set: { if !$0 { candidateMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(candidateMessage ?? "")
        }
    }
}

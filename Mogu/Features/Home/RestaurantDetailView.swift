//
//  RestaurantDetailView.swift
//  Mogu
//
//  Created by cmStudent on 2026/11/15.
//


import SwiftUI

struct RestaurantDetailView: View {

    @EnvironmentObject private var favoritesStore: FavoritesStore

    let restaurant: Restaurant

    @State private var showSafari = false
    @State private var showCandidateSelection = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                GeometryReader { geometry in
                    AsyncImage(
                        url: URL(string: restaurant.photo.mobile.l)
                    ) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: geometry.size.width,
                                height: 230
                            )
                            .clipped()
                    } placeholder: {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(Color.moguInk)
                            .frame(
                                width: geometry.size.width,
                                height: 230
                            )
                    }
                }
                .frame(height: 230)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            Genre.color(for: restaurant.genre.code),
                            lineWidth: 4
                        )
                }
                .padding(.horizontal, 16)

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

                    //URLに変換できない場合店舗情報ページへのボタンを表示しない
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
                                Color.moguFill,
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
                HStack(spacing: 16) {
                    Button {
                        //お気に入りの状態はStoreに任せて各画面で情報を共有
                        favoritesStore.toggleFavorite(restaurant)
                    } label: {
                        Image(
                            systemName: favoritesStore.isFavorite(restaurant.id)
                                ? "heart.fill"
                                : "heart"
                        )
                        .foregroundStyle(.red)
                    }

                    Button {
                        showCandidateSelection = true
                    } label: {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(Color.moguInk)
                    }
                    .accessibilityLabel("候補リストに追加")
                }
            }
        }

        .sheet(isPresented: $showSafari) {
            if let url = URL(string: restaurant.urls.pc) {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showCandidateSelection) {
            CandidateSelectionView(restaurant: restaurant)
        }
    }
}

//
//  SwiftUIView.swift
//  Mogu
//
//  Created by cmStudent on 2026/11/15.
//


import SwiftUI

struct RestaurantDetailView: View {

    let restaurant: Restaurant

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // 店舗写真
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

                    // 店名
                    Text(restaurant.name)
                        .font(.title2)
                        .bold()

                    // 料理ジャンル
                    Text(restaurant.genre.name)
                        .foregroundStyle(.secondary)

                    Divider()

                    // 予算
                    VStack(alignment: .leading, spacing: 5) {
                        Label("予算目安", systemImage: "yensign.circle")
                            .font(.headline)

                        Text(restaurant.budget.name)
                    }

                    Divider()

                    // 営業時間
                    VStack(alignment: .leading, spacing: 5) {
                        Label("営業時間", systemImage: "clock")
                            .font(.headline)

                        Text(restaurant.open)
                    }

                    Divider()

                    // 住所
                    VStack(alignment: .leading, spacing: 5) {
                        Label("住所", systemImage: "mappin.and.ellipse")
                            .font(.headline)

                        Text(restaurant.address)
                    }

                    // アクセス
                    VStack(alignment: .leading, spacing: 5) {
                        Label("アクセス", systemImage: "figure.walk")
                            .font(.headline)

                        Text(restaurant.access)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("店舗詳細")
        .navigationBarTitleDisplayMode(.inline)
    }
}


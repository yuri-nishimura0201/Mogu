//
//  Restaurant.swift
//  Mogu
//
//  Created by cmStudent on 2026/11/14.
//

import Foundation

struct Restaurant: Identifiable, Decodable {
    let id: String
    let name: String
    let address: String
    let access: String
    let open: String
    let lat: Double
    let lng: Double
    let photo: RestaurantPhoto
    let genre: RestaurantGenre
    let budget: RestaurantBudget
    let urls: RestaurantURLs
}

struct RestaurantPhoto: Decodable {
    let mobile: RestaurantPhotoMobile
}

struct RestaurantPhotoMobile: Decodable {
    let l: String
    let s: String
}

struct RestaurantResponse: Decodable {
    let results: RestaurantResults
}

struct RestaurantResults: Decodable {
    let shop: [Restaurant]
}

struct RestaurantGenre: Decodable {
    let name: String
}

struct RestaurantBudget: Decodable {
    let name: String
}

struct RestaurantURLs: Decodable {
    let pc: String
}

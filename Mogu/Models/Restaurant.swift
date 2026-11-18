//
//  Restaurant.swift
//  Mogu
//
//  Created by cmStudent on 2026/11/14.
//

import Foundation

struct Restaurant: Identifiable, Codable {
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

struct RestaurantPhoto: Codable {
    let mobile: RestaurantPhotoMobile
}

struct RestaurantPhotoMobile: Codable {
    let l: String
    let s: String
}

struct RestaurantResponse: Decodable {
    let results: RestaurantResults
}

struct RestaurantResults: Decodable {
    let shop: [Restaurant]
}

struct RestaurantGenre: Codable {
    let name: String
    let code: String?
}

struct RestaurantBudget: Codable {
    let name: String
    let code: String?
}

struct RestaurantURLs: Codable {
    let pc: String
}

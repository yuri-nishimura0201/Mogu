//
//  Restaurant.swift
//  Mogu
//
//  Created by cmStudent on 2026/11/14.
//

import Foundation
import CoreLocation

//APIからのデータ取得と端末保存、どちらにも対応するためCodableを使用
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

    //基準地点から店舗までの直線距離をm単位で取得
    func distance(from center: CLLocation) -> CLLocationDistance {
        CLLocation(latitude: lat, longitude: lng).distance(from: center)
    }
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
    let shop: [Restaurant]?
    let error: [HotPepperError]?
}

struct HotPepperError: Decodable {
    let code: Int
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

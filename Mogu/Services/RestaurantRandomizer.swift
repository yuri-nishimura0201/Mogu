struct RestaurantRandomizer {
    static func pick(from restaurants: [Restaurant]) -> Restaurant? {
        restaurants.randomElement()
    }
}

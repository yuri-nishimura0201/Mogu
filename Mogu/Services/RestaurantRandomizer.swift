struct RestaurantRandomizer {
    static func pick(
        from restaurants: [Restaurant],
        excluding previousID: String? = nil
    ) -> Restaurant? {
        let candidates = restaurants.filter {
            $0.id != previousID
        }

        return candidates.randomElement()
            ?? restaurants.randomElement()
    }
}

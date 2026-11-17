enum OpeningHoursFilter {
    case all
    case lunch
    case after23
    case mealAfter23
}

struct SearchFilters {
    var selectedGenres: Set<String> = []
    var range: Int = 3
    var budget: String?
    var openingHours: OpeningHoursFilter = .all
    var partyCapacity: Int?
    var selectedPartyOptions: Set<PartyOption> = []
    var selectedPreferences: Set<PreferenceOption> = []
}

enum PartyOption: String, Hashable {
    case privateRoom = "private_room"
    case charter = "charter"
    case course = "course"
    case freeDrink = "free_drink"
    case freeFood = "free_food"
    case horigotatsu = "horigotatsu"
}

enum PreferenceOption: String, Hashable {
    case card
    case nonSmoking = "non_smoking"

    case wifi
    case parking
    case barrierFree = "barrier_free"
    case english

    case pet
    case child
    case nightView = "night_view"
    case openAir = "open_air"

    case wine
    case sake
    case karaoke
    case tatami
}

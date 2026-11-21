enum SearchRange: Int, CaseIterable {
    case unspecified = 0, meters300 = 1, meters500 = 2
    case km1 = 3, km2 = 4, km3 = 5

    // APIには「指定なし」がないため、従来どおり最大範囲で検索する。
    var apiCode: Int { self == .unspecified ? Self.km3.rawValue : rawValue }

    var meters: Int? {
        switch self {
        case .unspecified: nil
        case .meters300: 300
        case .meters500: 500
        case .km1: 1000
        case .km2: 2000
        case .km3: 3000
        }
    }

    var title: String {
        guard let meters else { return "指定なし" }
        if meters < 1000 { return "\(meters)m以内" }
        return "\(meters / 1000)km以内"
    }
}

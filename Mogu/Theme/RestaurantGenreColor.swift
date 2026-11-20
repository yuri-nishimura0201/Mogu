import SwiftUI

enum RestaurantGenreColor {

    static func color(for code: String?) -> Color {
        switch code {

        case "G001":
            return rgb(255, 181, 111)

        case "G002":
            return rgb(163, 160, 233)

        case "G003":
            return rgb(192, 153, 233)

        case "G004":
            return rgb(145, 206, 136)

        case "G005":
            return rgb(245, 211, 93)

        case "G006":
            return rgb(245, 142, 166)

        case "G007":
            return rgb(240, 141, 111)

        case "G008":
            return rgb(233, 118, 130)

        case "G009":
            return rgb(103, 205, 189)

        case "G010":
            return rgb(134, 173, 238)

        case "G011":
            return rgb(198, 127, 203)

        case "G012":
            return rgb(138, 138, 205)

        case "G013":
            return rgb(233, 162, 76)

        case "G014":
            return rgb(235, 164, 200)

        case "G015":
            return rgb(164, 185, 178)

        case "G016":
            return rgb(216, 167, 123)

        case "G017":
            return rgb(235, 125, 176)

        default:
            return rgb(164, 185, 178)
        }
    }

    private static func rgb(
        _ red: Double,
        _ green: Double,
        _ blue: Double
    ) -> Color {
        Color(
            red: red / 255,
            green: green / 255,
            blue: blue / 255
        )
    }
}

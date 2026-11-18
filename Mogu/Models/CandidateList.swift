import Foundation

struct CandidateList: Identifiable, Codable {
    var id = UUID()
    var name: String
    var restaurants: [Restaurant] = []
}

import Foundation

struct CandidateList: Identifiable, Codable {
    var id = UUID()// 同じ名前のリストでも個別に識別できるようにUUIDを使用
    var name: String
    var restaurants: [Restaurant] = []
}

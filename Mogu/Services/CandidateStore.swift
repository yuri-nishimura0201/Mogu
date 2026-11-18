
import Foundation
import Combine

final class CandidateStore: ObservableObject {

    @Published private(set) var lists: [CandidateList] = []

    private let storageKey = "candidateLists"

    init() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return
        }

        do {
            lists = try JSONDecoder().decode([CandidateList].self, from: data)
        } catch {
            print("候補リストの読み込みエラー: \(error)")
        }
    }

    func addList(name: String) {
        let list = CandidateList(name: name)
        lists.append(list)
        saveLists()
    }

    func renameList(id: UUID, name: String) {
        guard let index = lists.firstIndex(where: { $0.id == id }) else {
            return
        }

        lists[index].name = name
        saveLists()
    }

    func deleteList(id: UUID) {
        lists.removeAll { $0.id == id }
        saveLists()
    }

    @discardableResult
    func addRestaurant(_ restaurant: Restaurant, to listID: UUID) -> Bool {
        guard let index = lists.firstIndex(where: { $0.id == listID }) else {
            return false
        }

        guard !lists[index].restaurants.contains(where: { $0.id == restaurant.id }) else {
            return false
        }

        lists[index].restaurants.append(restaurant)
        saveLists()
        return true
    }

    func removeRestaurant(id: String, from listID: UUID) {
        guard let index = lists.firstIndex(where: { $0.id == listID }) else {
            return
        }

        lists[index].restaurants.removeAll { $0.id == id }
        saveLists()
    }

    private func saveLists() {
        do {
            let data = try JSONEncoder().encode(lists)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("候補リストの保存エラー: \(error)")
        }
    }
}

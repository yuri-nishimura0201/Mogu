
import Foundation
import Combine

//候補リストの状態管理と保存
final class CandidateStore: ObservableObject {

    //メソッドを経由して更新する
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

    func addList(name: String, restaurants: [Restaurant] = []) {
        let list = CandidateList(name: name, restaurants: restaurants)
        lists.append(list)
        saveLists()
    }

    //リスト名の変更
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

    func addRestaurant(_ restaurant: Restaurant, to listID: UUID) {
        guard let index = lists.firstIndex(where: { $0.id == listID }) else {
            return
        }

        //候補リスト内の重複をふせぐ
        guard !lists[index].restaurants.contains(where: { $0.id == restaurant.id }) else {
            return
        }

        lists[index].restaurants.append(restaurant)
        saveLists()
    }

    func removeRestaurant(id: String, from listID: UUID) {
        guard let index = lists.firstIndex(where: { $0.id == listID }) else {
            return
        }

        lists[index].restaurants.removeAll { $0.id == id }
        saveLists()
    }

    func removeAll() {
        lists.removeAll()
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

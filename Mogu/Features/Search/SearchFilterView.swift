
import SwiftUI
import MapKit

enum SearchSource {
    case home
    case favorites
}

struct SearchFilterView: View {

    @Binding var filters: SearchFilters
    @Binding var showSearchFilter: Bool

    var source: SearchSource = .home
    var onRandom: (() -> Void)?
    @State private var stationName = ""
    @State private var isSearchingStation = false
    @State private var stationSearchError = false

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                Text(source == .favorites ? "お気に入りから絞り込み" : "検索・絞り込み")

                Spacer()

                Button("リセット") {
                    filters = SearchFilters()
                }
                .font(.caption)
                .foregroundStyle(.brown)
            }
            .padding()

            Divider()

            ScrollView {
            VStack(spacing: 0) {

                HStack(spacing: 14) {
                    Image(systemName: "location")
                        .foregroundStyle(.brown)
                        .frame(width: 24)

                    Text("エリア・場所")
                        .font(.subheadline)

                    Spacer()

                    Picker("場所", selection: Binding(
                        get: {
                            switch filters.location {
                            case .unspecified: return 0
                            case .currentLocation: return 1
                            case .station: return 2
                            }
                        },
                        set: { value in
                            switch value {
                            case 0:
                                filters.location = .unspecified
                            case 1:
                                filters.location = .currentLocation
                            default:
                                break
                            }
                        }
                    )) {
                        Text("指定なし").tag(0)
                        Text("現在地").tag(1)
                        if case .station = filters.location {
                            Text("駅指定").tag(2)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(.brown)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                Divider()

                HStack(spacing: 14) {
                    Image(systemName: "ruler")
                        .foregroundStyle(.brown)
                        .frame(width: 24)

                    Text("検索範囲")
                        .font(.subheadline)

                    Spacer()

                    Picker("検索範囲", selection: $filters.range) {
                        ForEach(searchRanges, id: \.value) { range in
                            Text(range.name)
                                .tag(range.value)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(.brown)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                HStack(spacing: 12) {
                    Image(systemName: "tram.fill")
                        .foregroundStyle(.brown)
                        .frame(width: 24)

                    TextField("駅名を入力（例：新宿駅）", text: $stationName)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.search)
                        .onSubmit {
                            Task {
                                await searchStation()
                            }
                        }

                    if isSearchingStation {
                        ProgressView()
                    }
                }

                if case .station(let name, _, _) = filters.location {
                    Text("選択中：\(name)")
                        .font(.caption)
                        .foregroundStyle(.brown)
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                }

                Divider()


                VStack(alignment: .leading, spacing: 12) {
                    Label("ジャンル", systemImage: "fork.knife")
                        .font(.subheadline)
                        .foregroundStyle(.brown)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(genres, id: \.code) { genre in
                                Button {
                                    if genre.code.isEmpty {
                                        filters.selectedGenres.removeAll()
                                    } else if filters.selectedGenres.contains(genre.code) {
                                        filters.selectedGenres.remove(genre.code)
                                    } else {
                                        filters.selectedGenres.insert(genre.code)
                                    }
                                } label: {

                                    Text(genre.name)
                                        .font(.subheadline)
                                        .foregroundStyle(
                                            isSelected(genre.code) ? Color.white : Color.brown
                                        )
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            isSelected(genre.code) ? Color.brown : Color.white,
                                            in: Capsule()
                                        )

                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }

                    Divider()
                }
                .padding(.vertical, 14)

                HStack(spacing: 14) {
                    Image(systemName: "yensign.circle")
                        .foregroundStyle(.brown)
                        .frame(width: 24)

                    Text("予算")
                        .font(.subheadline)

                    Spacer()

                    Picker(
                        "予算",
                        selection: Binding(
                            get: { filters.budget ?? "" },
                            set: { filters.budget = $0.isEmpty ? nil : $0 }
                        )
                    ) {
                        ForEach(budgets, id: \.code) { budget in
                            Text(budget.name)
                                .tag(budget.code)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(.brown)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                Divider()

                HStack(spacing: 14) {
                    Image(systemName: "clock")
                        .foregroundStyle(.brown)
                        .frame(width: 24)

                    Text("営業時間")
                        .font(.subheadline)

                    Spacer()

                    Picker("営業時間", selection: $filters.openingHours) {
                        Text("指定なし").tag(OpeningHoursFilter.all)
                        Text("ランチ営業あり").tag(OpeningHoursFilter.lunch)
                        Text("23時以降も営業").tag(OpeningHoursFilter.after23)
                        Text("23時以降も食事OK").tag(OpeningHoursFilter.mealAfter23)
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(.brown)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                Divider()

                NavigationLink {
                    PartyFilterView(filters: $filters)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "person.2")
                            .foregroundStyle(.brown)
                            .frame(width: 24)

                        Text("人数・宴会")
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(
                            filters.partyCapacity == nil &&
                            filters.selectedPartyOptions.isEmpty
                            ? "指定なし" : "指定済み"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.brown)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.brown)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                Divider()

                NavigationLink {
                    PreferenceFilterView(filters: $filters)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(.brown)
                            .frame(width: 24)

                        Text("こだわり条件")
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(
                            filters.selectedPreferences.isEmpty
                            ? "指定なし" : "指定済み"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.brown)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.brown)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                Divider()
            }
            }


            HStack(spacing: 12) {
                Button {
                    showSearchFilter = false
                } label: {
                    Label(
                        source == .favorites ? "一覧で見る" : "マップで見る",
                        systemImage: source == .favorites ? "list.bullet" : "map"
                    )
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        .brown,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                }

                if let onRandom {
                    Button(action: onRandom) {
                        Label("ランダム", systemImage: "shuffle")
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(.brown)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Color.white,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                    }
                }
            }
            .buttonStyle(.plain)
            .padding()
        }
        .background(Color(red: 1.0, green: 0.98, blue: 0.96))
        .alert("駅が見つかりませんでした", isPresented: $stationSearchError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("駅名を確認して、もう一度検索してください。")
        }
    }

    private func searchStation() async {
        let name = stationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        isSearchingStation = true
        defer { isSearchingStation = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = name.hasSuffix("駅") ? name : "\(name)駅"
        request.resultTypes = .pointOfInterest

        do {
            let response = try await MKLocalSearch(request: request).start()

            guard let station = response.mapItems.first else {
                stationSearchError = true
                return
            }

            let coordinate = station.placemark.coordinate

            filters.location = .station(
                name: station.name ?? name,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        } catch {
            stationSearchError = true
        }
    }


    private func isSelected(_ code: String) -> Bool {
        if code.isEmpty {
            return filters.selectedGenres.isEmpty
        }

        return filters.selectedGenres.contains(code)
    }

    private let searchRanges: [(name: String, value: Int)] = [
        ("指定なし", 0),
        ("300m以内", 1),
        ("500m以内", 2),
        ("1km以内", 3),
        ("2km以内", 4),
        ("3km以内", 5)
    ]

    private let budgets: [(name: String, code: String)] = [
        ("指定なし", ""),
        ("～500円", "B009"),
        ("501～1000円", "B010"),
        ("1001～1500円", "B011"),
        ("1501～2000円", "B001"),
        ("2001～3000円", "B002"),
        ("3001～4000円", "B003"),
        ("4001～5000円", "B008"),
        ("5001～7000円", "B004"),
        ("7001～10000円", "B005"),
        ("10001～15000円", "B006"),
        ("15001～20000円", "B012"),
        ("20001～30000円", "B013"),
        ("30001円～", "B014")
    ]


    private let genres: [(name: String, code: String)] = [
        ("すべて", ""),
        ("居酒屋", "G001"),
        ("ダイニングバー・バル", "G002"),
        ("創作料理", "G003"),
        ("和食", "G004"),
        ("洋食", "G005"),
        ("イタリアン・フレンチ", "G006"),
        ("中華", "G007"),
        ("焼肉・ホルモン", "G008"),
        ("アジア・エスニック料理", "G009"),
        ("各国料理", "G010"),
        ("カラオケ・パーティ", "G011"),
        ("バー・カクテル", "G012"),
        ("ラーメン", "G013"),
        ("カフェ・スイーツ", "G014"),
        ("その他グルメ", "G015"),
        ("お好み焼き・もんじゃ", "G016"),
        ("韓国料理", "G017")
    ]

}

#Preview {
    SearchFilterView(
        filters: .constant(SearchFilters()),
        showSearchFilter: .constant(true)
    )
}

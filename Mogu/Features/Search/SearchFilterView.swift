
import SwiftUI
import MapKit

enum SearchSource {
    case home
    case favorites
}

struct SearchFilterView: View {

    @ObservedObject var tutorial = MoguTutorial()
    @Binding var filters: SearchFilters
    @Binding var showSearchFilter: Bool
    var source: SearchSource = .home
    var onRandom: (() -> Void)?
    @State private var stationName = ""
    @StateObject private var stationSuggestions = StationSuggestionService()
    @FocusState private var isStationFieldFocused: Bool
    @State private var isSearchingStation = false
    @State private var stationSearchError = false

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                Text(source == .favorites ? "お気に入りから絞り込み" : "検索・絞り込み")

                Spacer()

                Button("リセット") {
                    filters = SearchFilters()
                    stationName = ""
                    stationSuggestions.clear()
                }
                .font(.caption)
                .foregroundStyle(Color.moguInk)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 0) {

                    HStack(spacing: 14) {
                        Image(systemName: "location")
                            .foregroundStyle(Color.moguInk)
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
                        .tint(.moguInk)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                    Divider()

                    HStack(spacing: 14) {
                        Image(systemName: "ruler")
                            .foregroundStyle(Color.moguInk)
                            .frame(width: 24)

                        Text("検索範囲")
                            .font(.subheadline)

                        Spacer()

                        Picker("検索範囲", selection: $filters.range) {
                            ForEach(SearchRange.allCases, id: \.self) { range in
                                Text(range.title)
                                    .tag(range)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .tint(.moguInk)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                    VStack(spacing: 4) {

                        HStack(spacing: 12) {
                            Image(systemName: "tram.fill")
                                .foregroundStyle(Color.moguInk)
                                .frame(width: 24)

                            TextField("駅名を入力（例：新宿駅）", text: $stationName)
                                .textFieldStyle(.roundedBorder)
                                .submitLabel(.search)
                                .focused($isStationFieldFocused)
                                .onChange(of: stationName) { _, newValue in
                                    if isStationFieldFocused {
                                        stationSuggestions.update(query: newValue)
                                    }
                                }
                                .onChange(of: isStationFieldFocused) { _, focused in
                                    if focused {
                                        stationSuggestions.update(query: stationName)
                                    } else {
                                        stationSuggestions.clear()
                                    }
                                }
                                .onSubmit {
                                    Task {
                                        await searchStation()
                                    }
                                }

                            if isSearchingStation {
                                ProgressView()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                        if isStationFieldFocused && !stationSuggestions.suggestions.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(
                                    Array(stationSuggestions.suggestions.prefix(5).enumerated()),
                                    id: \.offset
                                ) { item in

                                    Button {
                                        isStationFieldFocused = false

                                        Task {
                                            await selectStation(item.element)
                                        }
                                    } label: {
                                        HStack(spacing: 10) {
                                            Image(systemName: "tram.fill")
                                                .foregroundStyle(Color.moguInk)

                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(item.element.title)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.primary)

                                                if !item.element.subtitle.isEmpty {
                                                    Text(item.element.subtitle)
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }

                                            Spacer()
                                        }
                                        .padding(12)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)

                                    if item.offset < min(stationSuggestions.suggestions.count, 5) - 1 {
                                        Divider()
                                    }
                                }
                            }
                            .background(
                                .regularMaterial,
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .padding(.horizontal, 16)
                        }
                    }

                    if source == .home {
                        Divider()

                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Color.moguInk)
                                .frame(width: 24)

                            TextField(
                                "店舗名で検索（例：サイゼリヤ）",
                                text: $filters.restaurantName
                            )
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    if case .station(let name, _, _) = filters.location {
                        Text("選択中：\(name)")
                            .font(.caption)
                            .foregroundStyle(Color.moguInk)
                            .padding(.horizontal)
                            .padding(.bottom, 12)
                    }

                    Divider()


                    VStack(alignment: .leading, spacing: 12) {
                        Label("ジャンル", systemImage: "fork.knife")
                            .font(.subheadline)
                            .foregroundStyle(Color.moguInk)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                genreButton("すべて", code: "")
                                ForEach(Genre.all) { genre in
                                    genreButton(genre.japaneseName, code: genre.code)
                                }
                            }
                            .padding(.horizontal)
                        }

                        Divider()
                    }
                    .padding(.vertical, 14)

                    HStack(spacing: 14) {
                        Image(systemName: "yensign.circle")
                            .foregroundStyle(Color.moguInk)
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
                        .tint(.moguInk)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                    Divider()

                    HStack(spacing: 14) {
                        Image(systemName: "clock")
                            .foregroundStyle(Color.moguInk)
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
                        .tint(.moguInk)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                    Divider()

                    NavigationLink {
                        PartyFilterView(filters: $filters)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "person.2")
                                .foregroundStyle(Color.moguInk)
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
                            .foregroundStyle(Color.moguInk)

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Color.moguInk)
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
                                .foregroundStyle(Color.moguInk)
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
                            .foregroundStyle(Color.moguInk)

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Color.moguInk)
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
                    tutorial.advance(from: .editing, to: .favorite)
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
                        Color.moguFill,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                }

                .overlay(alignment: .top) {
                    if tutorial.step == .editing {
                        TutorialArrow(pointsDown: true)
                            .offset(y: -(TutorialArrow.diameter + TutorialArrow.gap))
                    }
                }

                if let onRandom {
                    Button(action: onRandom) {
                        Label("ランダム", systemImage: "shuffle")
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(Color.moguInk)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Color(.secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                    }
                    .disabled(tutorial.step == .editing)
                    .tutorialTarget(.random, active: tutorial.step == .random)
                }
            }
            .buttonStyle(.plain)
            .padding()
        }
        .background(Color.moguCanvas)
        .safeAreaInset(edge: .top) {
            if tutorial.step == .editing { TutorialHint(step: .editing, finish: tutorial.finish) }
        }
        .overlayPreferenceValue(TutorialBounds.self) { anchors in
            if tutorial.step == .random {
                GeometryReader { geometry in
                    TutorialSpotlight(step: .random, target: anchors[.random]?.first.map { geometry[$0] },
                                      finish: tutorial.finish)
                }
            }
        }
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
        //検索の結果に関わらず読み込み表示を解除
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

            let coordinate = station.location.coordinate

            filters.location = .station(
                name: station.name ?? name,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        } catch {
            stationSearchError = true
        }
    }

    @MainActor
    private func selectStation(_ completion: MKLocalSearchCompletion) async {

        isSearchingStation = true
        defer { isSearchingStation = false }

        let request = MKLocalSearch.Request(completion: completion)

        do {
            let response = try await MKLocalSearch(request: request).start()

            guard let station = response.mapItems.first else {
                stationSearchError = true
                return
            }

            let coordinate = station.location.coordinate
            let name = station.name ?? completion.title

            stationName = name

            filters.location = .station(
                name: name,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )

            stationSuggestions.clear()

        } catch {
            stationSearchError = true
        }
    }


    private func genreButton(_ title: String, code: String) -> some View {
        let selected = code.isEmpty ? filters.selectedGenres.isEmpty : filters.selectedGenres.contains(code)
        return Button {
            if code.isEmpty {
                filters.selectedGenres.removeAll()
            } else if selected {
                filters.selectedGenres.remove(code)
            } else {
                filters.selectedGenres.insert(code)
            }
        } label: {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(selected ? Color.white : Color.moguInk)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(selected ? Color.moguFill : Color(.secondarySystemGroupedBackground), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    //予算の表示名とAPIの予算コードを対応づける
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
}

#Preview {
    SearchFilterView(
        filters: .constant(SearchFilters()),
        showSearchFilter: .constant(true)
    )
}

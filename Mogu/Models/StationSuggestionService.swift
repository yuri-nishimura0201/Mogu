
import MapKit
import Combine

@MainActor
final class StationSuggestionService: NSObject, ObservableObject, @preconcurrency MKLocalSearchCompleterDelegate {

    @Published private(set) var suggestions: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()

        completer.delegate = self
        completer.resultTypes = .pointOfInterest
        completer.pointOfInterestFilter = MKPointOfInterestFilter(
            including: [.publicTransport]
        )
    }

    func update(query: String) {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !keyword.isEmpty else {
            clear()
            return
        }

        completer.queryFragment = keyword
    }

    func clear() {
        completer.queryFragment = ""
        suggestions = []
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results.filter {
            $0.title.contains("駅") ||
            $0.title.localizedCaseInsensitiveContains("station")
        }
    }
}

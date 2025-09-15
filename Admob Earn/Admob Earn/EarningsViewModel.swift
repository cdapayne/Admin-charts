import Foundation
import Combine

@MainActor
final class EarningsViewModel: ObservableObject {
    @Published var earnings: [Earning] = []
    @Published var filter: TimeFilter = .day {
        didSet { Task { await loadEarnings() } }
    }

    private let service = AdMobService()

    init() {
        Task { await loadEarnings() }
    }

    func loadEarnings() async {
        do {
            earnings = try await service.fetchEarnings(for: filter)
        } catch {
            print("Failed to fetch: \(error)")
        }
    }

    var total: Double {
        earnings.reduce(0) { $0 + $1.amount }
    }

    var groupedByApp: [(String, Double)] {
        let dict = Dictionary(grouping: earnings, by: { $0.appName })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        return dict.sorted { $0.key < $1.key }
    }

    var groupedByAdUnit: [(String, Double)] {
        let dict = Dictionary(grouping: earnings, by: { $0.adUnit })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        return dict.sorted { $0.key < $1.key }
    }
}

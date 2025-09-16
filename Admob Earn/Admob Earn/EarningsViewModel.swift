import Foundation
import Combine

@MainActor
final class EarningsViewModel: ObservableObject {
    @Published var earnings: [Earning] = []
    @Published var filter: TimeFilter = .day {
        didSet { Task { await loadEarnings() } }
    }
    @Published var account: AdMobAccount?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currencyCode: String = Locale.current.currency?.identifier ?? "USD"

    private let service = AdMobService()

    func connect() {
        Task {
            await performLoading {
                let connectedAccount = try await service.connect()
                account = connectedAccount
                if let currency = connectedAccount.currencyCode, !currency.isEmpty {
                    currencyCode = currency
                }
                try await refreshEarnings()
            }
        }
    }

    func loadEarnings() async {
        guard account != nil else { return }
        await performLoading {
            try await refreshEarnings()
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

    private func refreshEarnings() async throws {
        guard let account else { return }
        let report = try await service.fetchEarnings(for: filter, accountName: account.name)
        earnings = report.earnings
        if let currency = report.currencyCode, !currency.isEmpty {
            currencyCode = currency
        }
    }

    private func performLoading(_ operation: () async throws -> Void) async {
        if isLoading { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await operation()
        } catch {
            earnings = []
            if let localized = error as? LocalizedError, let description = localized.errorDescription {
                errorMessage = description
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }
}

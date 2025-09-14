import Foundation

final class AdMobService {
    private let oauth = OAuth2Manager()
    private var accessToken: String?

    func fetchEarnings(for filter: TimeFilter) async throws -> [Earning] {
        if accessToken == nil {
            accessToken = try? await oauth.signIn()
        }
        guard let token = accessToken else {
            return sampleData(for: filter)
        }

        var request = URLRequest(url: URL(string: "https://admob.googleapis.com/v1/networkReport:generate")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "dateRange": [
                "startDate": isoDate(filter.dateRange.start),
                "endDate": isoDate(filter.dateRange.end)
            ],
            "metrics": ["ESTIMATED_EARNINGS"],
            "dimensions": ["APP", "AD_UNIT"]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: request)
        // TODO: Parse response into [Earning]
        print(String(data: data, encoding: .utf8) ?? "")
        return sampleData(for: filter) // Placeholder until parsing is implemented
    }

    private func isoDate(_ date: Date) -> [String: Int] {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return ["year": comps.year!, "month": comps.month!, "day": comps.day!]
    }

    /// Generates sample data for previews and when no token is available.
    func sampleData(for filter: TimeFilter) -> [Earning] {
        let apps = ["Chat Fun", "News Reader", "Game Pro"]
        let units = ["BannerTop", "BannerBottom", "Rewarded"]
        let range = filter.dateRange
        var results: [Earning] = []
        var date = range.start
        while date <= range.end {
            for app in apps {
                for unit in units {
                    let amount = Double.random(in: 0...5)
                    results.append(Earning(date: date, appName: app, adUnit: unit, amount: amount))
                }
            }
            date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? range.end
        }
        return results
    }
}

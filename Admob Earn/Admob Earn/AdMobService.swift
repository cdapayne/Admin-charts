import Foundation

final class AdMobService {
    private let oauth = OAuth2Manager()
    private var accessToken: String?
    private let baseURL = URL(string: "https://admob.googleapis.com/v1")!
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    func connect() async throws -> AdMobAccount {
        let token = try await oauth.signIn()
        accessToken = token
        let accounts = try await listAccounts()
        guard let account = accounts.first else {
            throw ServiceError.noAccounts
        }
        return account
    }

    func fetchEarnings(for filter: TimeFilter, accountName: String) async throws -> (earnings: [Earning], currencyCode: String?) {
        guard !accountName.isEmpty else { return ([], nil) }
        let range = filter.dateRange
        var endDate = Calendar.current.date(byAdding: .day, value: -1, to: range.end) ?? range.end
        if endDate < range.start {
            endDate = range.start
        }
        let spec = NetworkReportRequest.ReportSpec(
            dateRange: DateRange(
                startDate: APIDate(date: range.start),
                endDate: APIDate(date: endDate)
            ),
            dimensions: ["DATE", "APP", "AD_UNIT"],
            metrics: ["ESTIMATED_EARNINGS"]
        )
        let requestBody = NetworkReportRequest(reportSpec: spec)
        let body = try encoder.encode(requestBody)
        var request = try makeRequest(path: "/\(accountName)/networkReport:generate", method: "POST")
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let data = try await send(request: request)
        do {
            let response = try decoder.decode(NetworkReportResponse.self, from: data)
            return parseRows(response.reportRows ?? [])
        } catch let error as DecodingError {
            throw ServiceError.decodingFailed(error)
        }
    }

    private func listAccounts() async throws -> [AdMobAccount] {
        let request = try makeRequest(path: "/accounts")
        let data = try await send(request: request)
        do {
            let response = try decoder.decode(ListAccountsResponse.self, from: data)
            return response.accounts ?? []
        } catch let error as DecodingError {
            throw ServiceError.decodingFailed(error)
        }
    }

    private func makeRequest(path: String, method: String = "GET") throws -> URLRequest {
        guard let token = accessToken else {
            throw ServiceError.notAuthorized
        }
        guard let url = URL(string: path, relativeTo: baseURL)?.absoluteURL else {
            throw ServiceError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func send(request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? ""
            throw ServiceError.apiError(statusCode: http.statusCode, message: message)
        }
        return data
    }

    private func parseRows(_ rows: [ReportRow]) -> (earnings: [Earning], currencyCode: String?) {
        var results: [Earning] = []
        var discoveredCurrency: String?

        for row in rows {
            guard let metric = row.metricValues["ESTIMATED_EARNINGS"],
                  let amount = metric.decimalValue else { continue }

            if discoveredCurrency == nil {
                discoveredCurrency = metric.currencyCode
            }

            let date = parseDate(from: row.dimensionValues["DATE"]?.value)
            let appName = row.dimensionValues["APP"]?.preferredLabel ?? "Unknown App"
            let adUnit = row.dimensionValues["AD_UNIT"]?.preferredLabel ?? "Ad Unit"

            let earning = Earning(
                date: date ?? Date(),
                appName: appName,
                adUnit: adUnit,
                amount: amount
            )
            results.append(earning)
        }

        return (results, discoveredCurrency)
    }

    private func parseDate(from value: String?) -> Date? {
        guard let value = value else { return nil }
        return dateFormatter.date(from: value)
    }
}

extension AdMobService {
    enum ServiceError: LocalizedError {
        case notAuthorized
        case invalidURL
        case noAccounts
        case apiError(statusCode: Int, message: String)
        case decodingFailed(DecodingError)

        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Please connect your Google account to continue."
            case .invalidURL:
                return "Failed to prepare the request."
            case .noAccounts:
                return "No AdMob accounts were found for this user."
            case .apiError(let status, let message):
                let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    return "Google returned an error (status code: \(status))."
                }
                return trimmed
            case .decodingFailed:
                return "Received an unexpected response from Google."
            }
        }
    }
}

private struct ListAccountsResponse: Decodable {
    let accounts: [AdMobAccount]?
}

private struct NetworkReportRequest: Encodable {
    let reportSpec: ReportSpec

    struct ReportSpec: Encodable {
        let dateRange: DateRange
        let dimensions: [String]
        let metrics: [String]
    }
}

private struct DateRange: Encodable {
    let startDate: APIDate
    let endDate: APIDate
}

private struct APIDate: Encodable {
    let year: Int
    let month: Int
    let day: Int

    init(date: Date) {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        self.year = components.year ?? 0
        self.month = components.month ?? 0
        self.day = components.day ?? 0
    }
}

private struct NetworkReportResponse: Decodable {
    let reportRows: [ReportRow]?
}

private struct ReportRow: Decodable {
    let dimensionValues: [String: DimensionValue]
    let metricValues: [String: MetricValue]
}

private struct DimensionValue: Decodable {
    let value: String?
    let displayLabel: String?

    var preferredLabel: String? {
        if let display = displayLabel, !display.isEmpty {
            return display
        }
        return value
    }
}

private struct MetricValue: Decodable {
    let doubleValue: Double?
    let microsValue: String?
    let currencyCode: String?

    var decimalValue: Double? {
        if let doubleValue { return doubleValue }
        if let microsValue, let micros = Double(microsValue) {
            return micros / 1_000_000
        }
        return nil
    }
}

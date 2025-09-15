import Foundation

struct Earning: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let appName: String
    let adUnit: String
    let amount: Double
}

enum TimeFilter: String, CaseIterable, Identifiable {
    case day = "1 Day"
    case week = "7 Days"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }

    var dateRange: DateInterval {
        let now = Date()
        switch self {
        case .day:
            return Calendar.current.dateInterval(of: .day, for: now)!
        case .week:
            return Calendar.current.dateInterval(of: .weekOfYear, for: now)!
        case .month:
            return Calendar.current.dateInterval(of: .month, for: now)!
        case .year:
            return Calendar.current.dateInterval(of: .year, for: now)!
        }
    }
}

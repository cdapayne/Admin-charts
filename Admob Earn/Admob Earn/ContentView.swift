import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var viewModel = EarningsViewModel()

    var body: some View {
        VStack {
            header
            Picker("Filter", selection: $viewModel.filter) {
                ForEach(TimeFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            ScrollView {
                EarningsChartView(data: viewModel.groupedByApp, title: "By App")
                EarningsChartView(data: viewModel.groupedByAdUnit, title: "By Ad Unit")
            }

            Spacer()

        }
        .padding()
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Today's Earnings")
                .font(.title2.bold())
            Text(viewModel.total, format: .currency(code: "USD"))
                .font(.largeTitle.bold())
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    ContentView()
}

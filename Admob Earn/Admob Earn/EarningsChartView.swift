import SwiftUI
import Charts

struct EarningsChartView: View {
    let data: [(String, Double)]
    let title: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            Chart {
                ForEach(data, id: \.0) { item in
                    BarMark(
                        x: .value("Amount", item.1),
                        y: .value("Key", item.0)
                    )
                }
            }
            .frame(height: 200)
            .padding()
        }
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        .padding()
    }
}

#Preview {
    EarningsChartView(data: [("App A", 20), ("App B", 10)], title: "By App")
}

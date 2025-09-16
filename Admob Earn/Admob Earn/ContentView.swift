import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var viewModel = EarningsViewModel()

    var body: some View {
        ZStack {
            Group {
                if let account = viewModel.account {
                    connectedContent(for: account)
                } else {
                    setupPrompt
                }
            }
            .animation(.easeInOut, value: viewModel.account?.id)

            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .overlay(alignment: .bottom) {
            if let message = viewModel.errorMessage {
                errorBanner(message)
                    .padding()
            }
        }
    }

    private func connectedContent(for account: AdMobAccount) -> some View {
        VStack {
            header(for: account)

            Picker("Filter", selection: $viewModel.filter) {
                ForEach(TimeFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .disabled(viewModel.isLoading)

            if viewModel.earnings.isEmpty && !viewModel.isLoading {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    Text("No earnings available for this range yet.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    EarningsChartView(data: viewModel.groupedByApp, title: "By App")
                    EarningsChartView(data: viewModel.groupedByAdUnit, title: "By Ad Unit")
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
    }

    private var setupPrompt: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Connect Google AdMob")
                    .font(.title3.bold())
                Text("Set up the app to use your Google OAuth account and load live earnings data.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            Button(action: viewModel.connect) {
                Label("Set Up Account", systemImage: "gearshape")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isLoading)
            .frame(maxWidth: 320)

            Spacer()
        }
        .padding(32)
    }

    private func header(for account: AdMobAccount) -> some View {
        VStack(spacing: 8) {
            Text(headerTitle)
                .font(.title2.bold())
            Text(viewModel.total, format: .currency(code: viewModel.currencyCode))
                .font(.largeTitle.bold())
            Text(account.preferredDisplayName)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
    }

    private var headerTitle: String {
        switch viewModel.filter {
        case .day: return "Today's Earnings"
        case .week: return "Last 7 Days"
        case .month: return "This Month"
        case .year: return "This Year"
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.15)
                .ignoresSafeArea()
            ProgressView()
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .transition(.opacity)
    }

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .multilineTextAlignment(.center)
            .font(.footnote)
            .foregroundStyle(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
    }
}

#Preview {
    ContentView()
}

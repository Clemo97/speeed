import ComposableArchitecture
import SwiftUI

struct DashboardView: View {
    @Bindable var store: StoreOf<DashboardFeature>

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    weeklyStatsSection
                    recentRunsSection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .onAppear { store.send(.onAppear) }
        } destination: { pathStore in
            switch pathStore.case {
            case .runDetail(let detailStore):
                RunDetailView(store: detailStore)
            }
        }
    }

    // MARK: Weekly Stats

    private var weeklyStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            HStack(spacing: 12) {
                statCard(
                    value: String(format: "%.1f km", store.weeklyDistanceMeters / 1000),
                    label: "Distance",
                    icon: "map.fill",
                    color: .orange
                )
                statCard(
                    value: "\(store.weeklyRunCount)",
                    label: "Runs",
                    icon: "figure.run",
                    color: .blue
                )
            }
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: .infinity)
    }

    // MARK: Recent Runs

    private var recentRunsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Runs")
                .font(.headline)

            if store.isLoading && store.recentRuns.isEmpty {
                ProgressView()
            } else if store.recentRuns.isEmpty {
                Text("No runs yet. Hit Record to start!")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(store.recentRuns) { run in
                    Button {
                        store.send(.runRowTapped(run))
                    } label: {
                        RunRowView(run: run)
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
        }
    }
}

#Preview {
    DashboardView(
        store: Store(initialState: DashboardFeature.State(userId: "preview")) {
            DashboardFeature()
        }
    )
}

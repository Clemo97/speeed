import ComposableArchitecture
import SwiftUI

struct RunHistoryView: View {
    @Bindable var store: StoreOf<RunHistoryFeature>

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            content
                .navigationTitle("Runs")
                .onAppear { store.send(.onAppear) }
        } destination: { pathStore in
            switch pathStore.case {
            case .runDetail(let detailStore):
                RunDetailView(store: detailStore)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.runs.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if store.runs.isEmpty {
            ContentUnavailableView(
                "No Runs Yet",
                systemImage: "figure.run",
                description: Text("Start your first run from the Record tab.")
            )
        } else {
            List(store.runs) { run in
                Button {
                    store.send(.runRowTapped(run))
                } label: {
                    RunRowView(run: run)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - Run Row

struct RunRowView: View {
    let run: Run

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(run.title ?? "Run")
                    .font(.headline)
                Text(run.startTime, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(run.formattedDistance)
                    .font(.headline)
                    .foregroundStyle(.orange)
                Text(run.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

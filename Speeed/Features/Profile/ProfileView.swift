import ComposableArchitecture
import SwiftUI

struct ProfileView: View {
    @Bindable var store: StoreOf<ProfileFeature>

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            ScrollView {
                VStack(spacing: 24) {
                    profileHeader
                    statsRow
                    runsSection
                }
                .padding()
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out", role: .destructive) {
                        store.send(.signOutTapped)
                    }
                }
            }
            .onAppear { store.send(.onAppear) }
        } destination: { pathStore in
            switch pathStore.case {
            case .runDetail(let detailStore):
                RunDetailView(store: detailStore)
            }
        }
    }

    // MARK: Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(.orange.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.orange)
                }

            if let profile = store.profile {
                Text(profile.displayTitle)
                    .font(.title2.bold())
                Text("@\(profile.username)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
        }
    }

    // MARK: Stats

    private var statsRow: some View {
        HStack {
            statsCell(
                value: String(format: "%.0f km", store.runs.reduce(0) { $0 + $1.distanceMeters } / 1000),
                label: "Total"
            )
            Divider().frame(height: 40)
            statsCell(
                value: "\(store.runs.count)",
                label: "Runs"
            )
            Divider().frame(height: 40)
            statsCell(
                value: store.runs.isEmpty ? "--"
                    : String(format: "%.1f km",
                              store.runs.reduce(0) { $0 + $1.distanceMeters } / Double(store.runs.count) / 1000),
                label: "Avg"
            )
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }

    private func statsCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(.orange)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Runs

    private var runsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Runs")
                .font(.headline)

            if store.runs.isEmpty && store.isLoading {
                ProgressView()
            } else if store.runs.isEmpty {
                Text("No completed runs yet.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(store.runs) { run in
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

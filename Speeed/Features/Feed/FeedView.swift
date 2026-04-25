import ComposableArchitecture
import SwiftUI

struct FeedView: View {
    @Bindable var store: StoreOf<FeedFeature>

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            content
                .navigationTitle("Feed")
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
                "Nothing Here Yet",
                systemImage: "list.bullet.rectangle",
                description: Text("Follow other runners to see their activities here.")
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

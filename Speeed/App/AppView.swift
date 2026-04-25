import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        Group {
            if store.isLoading {
                loadingView
            } else if store.isAuthenticated {
                AppTabsView(store: store.scope(state: \.tabs, action: \.tabs))
            } else {
                AuthView(store: store.scope(state: \.auth, action: \.auth))
            }
        }
        .onAppear { store.send(.onAppear) }
        .onOpenURL { url in
            store.send(.openURL(url))
        }
        .animation(.easeInOut(duration: 0.3), value: store.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: store.isLoading)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            ProgressView()
                .scaleEffect(1.2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    AppView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}

import ComposableArchitecture
import SwiftUI

struct AppTabsView: View {
    @Bindable var store: StoreOf<AppTabsFeature>

    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
            NavigationStack {
                DashboardView(store: store.scope(state: \.dashboard, action: \.dashboard))
            }
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }
            .tag(AppTabsFeature.State.Tab.dashboard)

            NavigationStack {
                RecordView(store: store.scope(state: \.record, action: \.record))
            }
            .tabItem {
                Label("Record", systemImage: "circle.fill")
            }
            .tag(AppTabsFeature.State.Tab.record)

            NavigationStack {
                FeedView(store: store.scope(state: \.feed, action: \.feed))
            }
            .tabItem {
                Label("Feed", systemImage: "list.bullet.rectangle.fill")
            }
            .tag(AppTabsFeature.State.Tab.feed)

            NavigationStack {
                ProfileView(store: store.scope(state: \.profile, action: \.profile))
            }
            .tabItem {
                Label("You", systemImage: "person.fill")
            }
            .tag(AppTabsFeature.State.Tab.profile)
        }
        .tint(.orange)
    }
}

#Preview {
    AppTabsView(
        store: Store(initialState: AppTabsFeature.State(userId: "preview-user")) {
            AppTabsFeature()
        }
    )
}

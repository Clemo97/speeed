import ComposableArchitecture
import Foundation

@Reducer struct AppTabsFeature {
    @ObservableState struct State: Equatable {
        var userId: String
        var selectedTab: Tab = .dashboard
        var dashboard: DashboardFeature.State
        var record: RecordFeature.State
        var feed: FeedFeature.State
        var profile: ProfileFeature.State

        init(userId: String = "") {
            self.userId = userId
            self.dashboard = DashboardFeature.State(userId: userId)
            self.record = RecordFeature.State(userId: userId)
            self.feed = FeedFeature.State(userId: userId)
            self.profile = ProfileFeature.State(userId: userId)
        }

        enum Tab: Hashable {
            case dashboard
            case record
            case feed
            case profile
        }
    }

    enum Action {
        case dashboard(DashboardFeature.Action)
        case record(RecordFeature.Action)
        case feed(FeedFeature.Action)
        case profile(ProfileFeature.Action)
        case tabSelected(State.Tab)
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.dashboard, action: \.dashboard) { DashboardFeature() }
        Scope(state: \.record, action: \.record) { RecordFeature() }
        Scope(state: \.feed, action: \.feed) { FeedFeature() }
        Scope(state: \.profile, action: \.profile) { ProfileFeature() }

        Reduce { state, action in
            switch action {
            case .tabSelected(let tab):
                state.selectedTab = tab
                return .none
            case .dashboard, .record, .feed, .profile:
                return .none
            }
        }
    }
}

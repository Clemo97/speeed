import ComposableArchitecture
import Dependencies
import Foundation
import Supabase

@Reducer struct AppFeature {
    @ObservableState struct State: Equatable {
        var isLoading = true
        var isAuthenticated = false
        var currentUserId: String?
        var auth = AuthFeature.State()
        var tabs = AppTabsFeature.State()
    }

    enum Action {
        case auth(AuthFeature.Action)
        case tabs(AppTabsFeature.Action)
        case onAppear
        case openURL(URL)
        case authStateChanged(AuthChangeEvent, Session?)
    }

    @Dependency(\.supabaseClient) var supabaseClient

    var body: some Reducer<State, Action> {
        Scope(state: \.auth, action: \.auth) { AuthFeature() }
        Scope(state: \.tabs, action: \.tabs) { AppTabsFeature() }

        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    for await (event, session) in await supabaseClient.auth.authStateChanges {
                        await send(.authStateChanged(event, session))
                    }
                }

            case let .authStateChanged(event, session):
                switch event {
                case .initialSession, .signedIn, .tokenRefreshed:
                    guard let session else {
                        state.isLoading = false
                        state.isAuthenticated = false
                        state.currentUserId = nil
                        return .none
                    }
                    let userId = session.user.id.uuidString
                    state.currentUserId = userId
                    state.isAuthenticated = true
                    state.isLoading = false
                    state.tabs = AppTabsFeature.State(userId: userId)
                    return .none

                case .signedOut, .userDeleted:
                    state.isAuthenticated = false
                    state.currentUserId = nil
                    state.isLoading = false
                    state.auth = AuthFeature.State()
                    return .none

                default:
                    state.isLoading = false
                    return .none
                }

            case let .openURL(url):
                return .run { _ in
                    try? await supabaseClient.auth.session(from: url)
                }

            case .auth, .tabs:
                return .none
            }
        }
    }
}

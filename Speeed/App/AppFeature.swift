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
        case powerSyncConnected
        case powerSyncConnectionFailed(String)
    }

    @Dependency(\.supabaseClient) var supabaseClient
    @Dependency(\.powerSyncDatabase) var database
    @Dependency(\.connector) var connector

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
                    state.tabs = AppTabsFeature.State(userId: userId)
                    state.isLoading = true
                    return .run { send in
                        do {
                            try await database.connect(connector: connector)
                            try await database.waitForFirstSync()
                            await send(.powerSyncConnected)
                        } catch {
                            await send(.powerSyncConnectionFailed(error.localizedDescription))
                        }
                    }

                case .signedOut, .userDeleted:
                    state.isAuthenticated = false
                    state.currentUserId = nil
                    state.isLoading = false
                    state.auth = AuthFeature.State()
                    return .run { _ in
                        try? await database.disconnectAndClear()
                    }

                default:
                    state.isLoading = false
                    return .none
                }

            case let .openURL(url):
                return .run { _ in
                    try? await supabaseClient.auth.session(from: url)
                }

            case .powerSyncConnected:
                state.isLoading = false
                return .none

            case .powerSyncConnectionFailed:
                // Still show app — offline reads from local SQLite work without connection
                state.isLoading = false
                return .none

            case .auth, .tabs:
                return .none
            }
        }
    }
}

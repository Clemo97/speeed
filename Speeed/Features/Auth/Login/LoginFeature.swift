import ComposableArchitecture
import Dependencies
import Foundation
import Supabase

@Reducer struct LoginFeature {
    @ObservableState struct State: Equatable {
        var email = ""
        var password = ""
        var isLoading = false
        var errorMessage: String?
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case signInWithEmailTapped
        case signInWithGoogleTapped
        case signInSucceeded
        case signInFailed(String)
        case errorDismissed
    }

    @Dependency(\.supabaseClient) var supabaseClient

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .signInWithEmailTapped:
                guard !state.email.isEmpty, !state.password.isEmpty else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                let email = state.email
                let password = state.password
                return .run { send in
                    do {
                        try await supabaseClient.auth.signIn(email: email, password: password)
                        await send(.signInSucceeded)
                    } catch {
                        await send(.signInFailed(error.localizedDescription))
                    }
                }

            case .signInWithGoogleTapped:
                state.isLoading = true
                return .run { send in
                    do {
                        try await supabaseClient.auth.signInWithOAuth(
                            provider: .google,
                            redirectTo: URL(string: "com.speeed://auth-callback")
                        )
                        await send(.signInSucceeded)
                    } catch {
                        await send(.signInFailed(error.localizedDescription))
                    }
                }

            case .signInSucceeded:
                state.isLoading = false
                return .none

            case .signInFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .errorDismissed:
                state.errorMessage = nil
                return .none
            }
        }
    }
}

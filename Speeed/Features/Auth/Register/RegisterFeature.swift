import ComposableArchitecture
import Dependencies
import Foundation
import Supabase

@Reducer struct RegisterFeature {
    @ObservableState struct State: Equatable {
        var email = ""
        var password = ""
        var confirmPassword = ""
        var username = ""
        var isLoading = false
        var errorMessage: String?

        var passwordsMatch: Bool { password == confirmPassword }
        var isFormValid: Bool {
            !email.isEmpty && !password.isEmpty && !username.isEmpty
                && password.count >= 8 && passwordsMatch
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case registerTapped
        case registerSucceeded
        case registerFailed(String)
        case errorDismissed
    }

    @Dependency(\.supabaseClient) var supabaseClient

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .registerTapped:
                guard state.isFormValid else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                let email = state.email
                let password = state.password
                let username = state.username
                return .run { send in
                    do {
                        try await supabaseClient.auth.signUp(
                            email: email,
                            password: password,
                            data: ["preferred_username": AnyJSON.string(username)]
                        )
                        await send(.registerSucceeded)
                    } catch {
                        await send(.registerFailed(error.localizedDescription))
                    }
                }

            case .registerSucceeded:
                state.isLoading = false
                return .none

            case .registerFailed(let message):
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

import ComposableArchitecture
import Dependencies
import Foundation
import Supabase

@Reducer struct AuthFeature {
    @ObservableState struct State: Equatable {
        var login = LoginFeature.State()
        var register = RegisterFeature.State()
        var isShowingRegister = false
        var errorMessage: String?
    }

    enum Action {
        case login(LoginFeature.Action)
        case register(RegisterFeature.Action)
        case showRegisterTapped
        case showLoginTapped
        case errorDismissed
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.login, action: \.login) { LoginFeature() }
        Scope(state: \.register, action: \.register) { RegisterFeature() }

        Reduce { state, action in
            switch action {
            case .showRegisterTapped:
                state.isShowingRegister = true
                return .none

            case .showLoginTapped:
                state.isShowingRegister = false
                return .none

            case .errorDismissed:
                state.errorMessage = nil
                return .none

            case .login, .register:
                return .none
            }
        }
    }
}

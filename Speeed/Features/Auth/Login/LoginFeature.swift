import AuthenticationServices
import ComposableArchitecture
import CryptoKit
import Dependencies
import Foundation
import Supabase

@Reducer struct LoginFeature {
    @ObservableState struct State: Equatable {
        var email = ""
        var password = ""
        var isLoading = false
        var errorMessage: String?

        // Apple Sign In nonce — generated fresh on each attempt
        var currentNonce: String?
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case signInWithEmailTapped
        case signInWithAppleTapped
        case signInWithGoogleTapped
        case appleSignInCompleted(Result<ASAuthorization, Error>)
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

            case .signInWithAppleTapped:
                let nonce = randomNonceString()
                state.currentNonce = nonce
                // ASAuthorizationController is handled in the View
                return .none

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

            case let .appleSignInCompleted(.success(authorization)):
                guard
                    let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                    let identityTokenData = credential.identityToken,
                    let identityToken = String(data: identityTokenData, encoding: .utf8),
                    let nonce = state.currentNonce
                else {
                    state.isLoading = false
                    state.errorMessage = "Apple Sign In failed — invalid credential"
                    return .none
                }
                state.isLoading = true
                return .run { send in
                    do {
                        try await supabaseClient.auth.signInWithIdToken(
                            credentials: .init(
                                provider: .apple,
                                idToken: identityToken,
                                nonce: nonce
                            )
                        )
                        await send(.signInSucceeded)
                    } catch {
                        await send(.signInFailed(error.localizedDescription))
                    }
                }

            case .appleSignInCompleted(.failure(let error)):
                state.isLoading = false
                if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                    state.errorMessage = error.localizedDescription
                }
                return .none

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

// MARK: - Apple Sign In Nonce Helpers

private func randomNonceString(length: Int = 32) -> String {
    var randomBytes = [UInt8](repeating: 0, count: length)
    _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
    return randomBytes.map { String(format: "%02x", $0) }.joined()
}

func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashed = SHA256.hash(data: inputData)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
}



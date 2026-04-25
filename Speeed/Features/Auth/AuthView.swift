import ComposableArchitecture
import SwiftUI

struct AuthView: View {
    @Bindable var store: StoreOf<AuthFeature>

    var body: some View {
        if store.isShowingRegister {
            RegisterView(store: store.scope(state: \.register, action: \.register))
                .overlay(alignment: .topLeading) {
                    Button("Sign In") {
                        store.send(.showLoginTapped)
                    }
                    .padding()
                }
        } else {
            LoginView(store: store.scope(state: \.login, action: \.login))
                .overlay(alignment: .bottom) {
                    Button("Create an account") {
                        store.send(.showRegisterTapped)
                    }
                    .padding()
                }
        }
    }
}

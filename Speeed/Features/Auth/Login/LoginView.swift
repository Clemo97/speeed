import ComposableArchitecture
import SwiftUI

struct LoginView: View {
    @Bindable var store: StoreOf<LoginFeature>

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: Header
                VStack(spacing: 8) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 72))
                        .foregroundStyle(.orange)
                    Text("Speeed")
                        .font(.largeTitle.bold())
                    Text("Track every run.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)

                // MARK: Email + Password
                VStack(spacing: 12) {
                    TextField("Email", text: $store.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Password", text: $store.password)
                        .textContentType(.password)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        store.send(.signInWithEmailTapped)
                    } label: {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(store.isLoading || store.email.isEmpty || store.password.isEmpty)
                }
                .padding(.horizontal)

                // MARK: Divider
                HStack {
                    Divider()
                    Text("or")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Divider()
                }
                .padding(.horizontal)

                // MARK: Google Sign In
                Button {
                    store.send(.signInWithGoogleTapped)
                } label: {
                    HStack {
                        Image(systemName: "globe")
                        Text("Sign in with Google")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.primary)
                .frame(height: 50)
                .padding(.horizontal)

                if store.isLoading {
                    ProgressView()
                }
            }
            .padding(.bottom, 40)
        }
        .alert("Sign In Failed", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.send(.errorDismissed) } }
        )) {
            Button("OK") { store.send(.errorDismissed) }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
}

#Preview {
    LoginView(
        store: Store(initialState: LoginFeature.State()) {
            LoginFeature()
        }
    )
}

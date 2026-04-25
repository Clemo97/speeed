import ComposableArchitecture
import SwiftUI

struct RegisterView: View {
    @Bindable var store: StoreOf<RegisterFeature>

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 56))
                        .foregroundStyle(.orange)
                    Text("Create Account")
                        .font(.title.bold())
                }
                .padding(.top, 40)

                VStack(spacing: 12) {
                    TextField("Username", text: $store.username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)

                    TextField("Email", text: $store.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Password (min 8 characters)", text: $store.password)
                        .textContentType(.newPassword)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Confirm Password", text: $store.confirmPassword)
                        .textContentType(.newPassword)
                        .textFieldStyle(.roundedBorder)

                    if !store.confirmPassword.isEmpty && !store.passwordsMatch {
                        Text("Passwords don't match")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button {
                        store.send(.registerTapped)
                    } label: {
                        Text("Create Account")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(!store.isFormValid || store.isLoading)
                }
                .padding(.horizontal)

                if store.isLoading {
                    ProgressView()
                }
            }
            .padding(.bottom, 40)
        }
        .alert("Registration Failed", isPresented: Binding(
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
    RegisterView(
        store: Store(initialState: RegisterFeature.State()) {
            RegisterFeature()
        }
    )
}

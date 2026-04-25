import ComposableArchitecture
import SwiftUI

struct RecordView: View {
    @Bindable var store: StoreOf<RecordFeature>

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.orange)

            Text("Ready to Run?")
                .font(.title2.bold())

            Text("Tap below to start tracking your GPS route, pace, and distance.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button {
                store.send(.startRunTapped)
            } label: {
                Label("Start Run", systemImage: "play.fill")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .navigationTitle("Record")
        .fullScreenCover(
            item: $store.scope(state: \.activeRun, action: \.activeRun)
        ) { runStore in
            ActiveRunView(store: runStore)
        }
    }
}

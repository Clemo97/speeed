import ComposableArchitecture
import SwiftUI

struct SaveRunView: View {
    @Bindable var store: StoreOf<SaveRunFeature>
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Run Summary
                HStack(spacing: 0) {
                    summaryCell(
                        value: Run.formattedDistance(store.distanceMeters),
                        label: "Distance"
                    )
                    Divider().frame(height: 40)
                    summaryCell(
                        value: Run.formattedDuration(store.durationSeconds),
                        label: "Time"
                    )
                    Divider().frame(height: 40)
                    summaryCell(
                        value: Run.formattedPace(store.averagePaceSecondsPerKm),
                        label: "Avg Pace"
                    )
                }
                .padding()
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

                // Title field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title (optional)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Morning Run", text: $store.title)
                        .textFieldStyle(.roundedBorder)
                }

                // Visibility
                Toggle("Share publicly", isOn: $store.isPublic)
                    .tint(.orange)

                Spacer()

                // Save / Discard
                VStack(spacing: 12) {
                    Button {
                        store.send(.saveTapped)
                    } label: {
                        Group {
                            if store.isLoading {
                                ProgressView()
                            } else {
                                Text("Save Run")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(store.isLoading)

                    Button(role: .destructive) {
                        store.send(.discardTapped)
                        dismiss()
                    } label: {
                        Text("Discard Run")
                    }
                    .disabled(store.isLoading)
                }
            }
            .padding()
            .navigationTitle("Save Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Save Failed", isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.send(.errorDismissed) } }
            )) {
                Button("OK") { store.send(.errorDismissed) }
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
        .onChange(of: store.isLoading) { _, isLoading in
            if !isLoading && store.errorMessage == nil {
                dismiss()
            }
        }
    }

    private func summaryCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Static formatting helpers used by SaveRunView

private extension Run {
    static func formattedDistance(_ meters: Double) -> String {
        String(format: "%.2f km", meters / 1000)
    }

    static func formattedDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }

    static func formattedPace(_ pace: Double) -> String {
        guard pace > 0 else { return "--:--" }
        let m = Int(pace) / 60
        let s = Int(pace) % 60
        return String(format: "%d:%02d /km", m, s)
    }
}

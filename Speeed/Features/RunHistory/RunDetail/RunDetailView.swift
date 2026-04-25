import ComposableArchitecture
import MapKit
import SwiftUI

struct RunDetailView: View {
    let store: StoreOf<RunDetailFeature>

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: Map
                mapSection
                    .frame(height: 300)

                // MARK: Stats
                statsSection
                    .padding()

                Divider()

                // MARK: Splits
                if !store.splits.isEmpty {
                    splitsSection
                        .padding()
                }
            }
        }
        .navigationTitle(store.run.title ?? "Run")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.send(.onAppear) }
    }

    // MARK: Map Section

    @ViewBuilder
    private var mapSection: some View {
        if store.isLoadingLocations {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.secondarySystemBackground))
        } else {
            Map(initialPosition: mapInitialPosition) {
                if store.coordinates.count >= 2 {
                    MapPolyline(coordinates: store.coordinates, contourStyle: .geodesic)
                        .stroke(.orange, lineWidth: 4)
                }
                if let start = store.startCoordinate {
                    Marker("Start", coordinate: start)
                        .tint(.green)
                }
                if let end = store.endCoordinate, store.coordinates.count > 1 {
                    Marker("Finish", coordinate: end)
                        .tint(.red)
                }
            }
            .mapStyle(.hybrid(elevation: .realistic, showsTraffic: false))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
        }
    }

    private var mapInitialPosition: MapCameraPosition {
        guard store.coordinates.count >= 2 else {
            return .automatic
        }
        return .automatic
    }

    // MARK: Stats Section

    private var statsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 20) {
            statCell(value: store.run.formattedDistance, label: "Distance")
            statCell(value: store.run.formattedDuration, label: "Time")
            statCell(value: store.run.formattedPace, label: "Avg Pace")
        }
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.orange)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: Splits Section

    private var splitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Splits")
                .font(.headline)

            ForEach(Array(store.splits.enumerated()), id: \.offset) { _, split in
                HStack {
                    Text(split.label)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(split.pace + " /km")
                        .font(.body.monospacedDigit())
                        .bold()
                }
                Divider()
            }
        }
    }
}

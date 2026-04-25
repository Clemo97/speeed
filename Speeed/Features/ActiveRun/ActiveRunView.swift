import ComposableArchitecture
import MapKit
import SwiftUI

struct ActiveRunView: View {
    @Bindable var store: StoreOf<ActiveRunFeature>
    @State private var mapCameraPosition: MapCameraPosition = .userLocation(
        followsHeading: true,
        fallback: .automatic
    )

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: Live Map
            Map(position: $mapCameraPosition) {
                // Live-growing route polyline
                if store.coordinates.count >= 2 {
                    MapPolyline(coordinates: store.coordinates, contourStyle: .geodesic)
                        .stroke(.orange, lineWidth: 5)
                }
                // Current location dot
                UserAnnotation()
            }
            .mapStyle(.hybrid(elevation: .realistic, showsTraffic: false))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .ignoresSafeArea()

            // MARK: Stats + Controls overlay
            VStack(spacing: 0) {
                statsPanel
                controlsPanel
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .sheet(
            item: $store.scope(state: \.saveRun, action: \.saveRun)
        ) { saveStore in
            SaveRunView(store: saveStore)
                .presentationDetents([.medium])
        }
    }

    // MARK: Stats Panel

    private var statsPanel: some View {
        HStack(spacing: 0) {
            statCell(value: store.formattedElapsed, label: "Time")
            Divider().frame(height: 40)
            statCell(value: store.formattedDistance, label: "Distance")
            Divider().frame(height: 40)
            statCell(value: store.formattedPace, label: "Pace /km")
        }
        .padding(.vertical, 20)
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold().monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Controls Panel

    private var controlsPanel: some View {
        HStack(spacing: 24) {
            if store.phase == .notStarted {
                startButton
            } else if store.phase == .running {
                pauseButton
                stopButton
            } else if store.phase == .paused {
                resumeButton
                stopButton
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal)
    }

    private var startButton: some View {
        Button {
            store.send(.startTapped)
        } label: {
            Circle()
                .fill(.green)
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: "play.fill")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
        }
    }

    private var pauseButton: some View {
        Button {
            store.send(.pauseTapped)
        } label: {
            Circle()
                .fill(.orange)
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: "pause.fill")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
        }
    }

    private var resumeButton: some View {
        Button {
            store.send(.resumeTapped)
        } label: {
            Circle()
                .fill(.green)
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: "play.fill")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
        }
    }

    private var stopButton: some View {
        Button {
            store.send(.stopTapped)
        } label: {
            Circle()
                .fill(.red)
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: "stop.fill")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
        }
    }
}

#Preview {
    ActiveRunView(
        store: Store(
            initialState: ActiveRunFeature.State(userId: "preview-user")
        ) {
            ActiveRunFeature()
        }
    )
}

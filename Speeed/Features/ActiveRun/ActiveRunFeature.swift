import ComposableArchitecture
import CoreLocation
import Dependencies
import Foundation

@Reducer struct ActiveRunFeature {
    @ObservableState struct State: Equatable {
        var userId: String

        // Run state
        var phase: Phase = .notStarted
        var elapsed: TimeInterval = 0
        var distanceMeters: Double = 0
        var coordinates: [CLLocationCoordinate2D] = []
        var currentSpeedMps: Double = 0  // meters per second

        // Sheet on stop
        @Presents var saveRun: SaveRunFeature.State?

        enum Phase: Equatable {
            case notStarted
            case running
            case paused
        }

        // MARK: Computed
        var isRunning: Bool { phase == .running }
        var isPaused: Bool { phase == .paused }

        /// Current pace in seconds per km. Returns nil if speed is near-zero.
        var currentPaceSecondsPerKm: Double? {
            guard currentSpeedMps > 0.5 else { return nil }
            return 1000 / currentSpeedMps
        }

        var formattedElapsed: String {
            let total = Int(elapsed)
            let hours = total / 3600
            let minutes = (total % 3600) / 60
            let seconds = total % 60
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            }
            return String(format: "%02d:%02d", minutes, seconds)
        }

        var formattedDistance: String {
            String(format: "%.2f km", distanceMeters / 1000)
        }

        var formattedPace: String {
            guard let pace = currentPaceSecondsPerKm else { return "--:--" }
            let minutes = Int(pace) / 60
            let seconds = Int(pace) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }

        var averagePaceSecondsPerKm: Double {
            guard distanceMeters > 0, elapsed > 0 else { return 0 }
            return elapsed / (distanceMeters / 1000)
        }
    }

    enum Action {
        case saveRun(PresentationAction<SaveRunFeature.Action>)
        case startTapped
        case pauseTapped
        case resumeTapped
        case stopTapped
        case discardTapped
        case locationUpdate(CLLocationUpdate)
        case locationError(String)
        case timerTick
    }

    enum CancelID {
        case locationStream
        case timer
    }

    @Dependency(\.locationClient) var locationClient
    @Dependency(\.date.now) var now

    private var startTime: Date?

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .startTapped:
                state.phase = .running
                return .merge(
                    startLocationStream(),
                    startTimer()
                )

            case .pauseTapped:
                state.phase = .paused
                return .cancel(id: CancelID.timer)

            case .resumeTapped:
                state.phase = .running
                return startTimer()

            case .stopTapped:
                state.phase = .paused
                state.saveRun = SaveRunFeature.State(
                    userId: state.userId,
                    distanceMeters: state.distanceMeters,
                    durationSeconds: state.elapsed,
                    averagePaceSecondsPerKm: state.averagePaceSecondsPerKm,
                    coordinates: state.coordinates
                )
                return .merge(
                    .cancel(id: CancelID.locationStream),
                    .cancel(id: CancelID.timer)
                )

            case .discardTapped:
                return .merge(
                    .cancel(id: CancelID.locationStream),
                    .cancel(id: CancelID.timer)
                )

            case let .locationUpdate(update):
                guard state.phase == .running else { return .none }
                let isStationary: Bool
                if #available(iOS 18.0, *) {
                    isStationary = update.stationary
                } else {
                    isStationary = update.isStationary  // swiftlint:disable:this deprecated_usage
                }
                guard !isStationary, let location = update.location else { return .none }

                let newCoord = location.coordinate
                state.currentSpeedMps = max(location.speed, 0)

                if let last = state.coordinates.last {
                    let lastLocation = CLLocation(latitude: last.latitude, longitude: last.longitude)
                    let increment = location.distance(from: lastLocation)
                    // Filter GPS noise — ignore jumps larger than 50m between updates
                    if increment < 50 {
                        state.distanceMeters += increment
                    }
                }
                state.coordinates.append(newCoord)
                return .none

            case .locationError:
                // Non-fatal — GPS can recover. Keep running.
                return .none

            case .timerTick:
                guard state.phase == .running else { return .none }
                state.elapsed += 1
                return .none

            case .saveRun(.presented(.saveTapped)):
                return .none

            case .saveRun(.presented(.discardTapped)):
                return .none

            case .saveRun:
                return .none
            }
        }
        .ifLet(\.$saveRun, action: \.saveRun) {
            SaveRunFeature()
        }
    }

    // MARK: Effect Factories

    private func startLocationStream() -> Effect<Action> {
        .run { send in
            for try await update in locationClient.liveUpdates() {
                await send(.locationUpdate(update))
            }
        } catch: { error, send in
            await send(.locationError(error.localizedDescription))
        }
        .cancellable(id: CancelID.locationStream)
    }

    private func startTimer() -> Effect<Action> {
        .run { send in
            while true {
                try await Task.sleep(for: .seconds(1))
                await send(.timerTick)
            }
        }
        .cancellable(id: CancelID.timer)
    }
}

// MARK: - CLLocationCoordinate2D + Equatable

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}



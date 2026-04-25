import ComposableArchitecture
import CoreLocation
import Foundation
import MapKit

@Reducer struct RunDetailFeature {
    @ObservableState struct State: Equatable {
        var run: Run
        var locations: [RunLocation] = []
        var isLoadingLocations = true

        var coordinates: [CLLocationCoordinate2D] {
            locations
                .sorted { $0.sequence < $1.sequence }
                .map(\.coordinate)
        }

        var startCoordinate: CLLocationCoordinate2D? { coordinates.first }
        var endCoordinate: CLLocationCoordinate2D? { coordinates.last }

        /// Per-km splits: array of (km label, pace string)
        var splits: [(label: String, pace: String)] {
            guard locations.count >= 2 else { return [] }
            let sorted = locations.sorted { $0.sequence < $1.sequence }
            var splits: [(label: String, pace: String)] = []
            var kmStart = sorted.first!
            var accumulated = 0.0
            var splitIndex = 1

            for i in 1..<sorted.count {
                let prev = sorted[i - 1]
                let curr = sorted[i]
                let prevLoc = CLLocation(latitude: prev.latitude, longitude: prev.longitude)
                let currLoc = CLLocation(latitude: curr.latitude, longitude: curr.longitude)
                accumulated += currLoc.distance(from: prevLoc)

                if accumulated >= 1000 {
                    let time = curr.recordedAt.timeIntervalSince(kmStart.recordedAt)
                    let paceSecondsPerKm = time / (accumulated / 1000)
                    let m = Int(paceSecondsPerKm) / 60
                    let s = Int(paceSecondsPerKm) % 60
                    splits.append((
                        label: "km \(splitIndex)",
                        pace: String(format: "%d:%02d", m, s)
                    ))
                    kmStart = curr
                    accumulated = 0
                    splitIndex += 1
                }
            }
            return splits
        }
    }

    enum Action {
        case onAppear
        case locationsLoaded([RunLocation])
    }

    @Dependency(\.powerSyncDatabase) var database

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let runId = state.run.id
                return .run { send in
                    for try await rows in try database.watch(
                        sql: "SELECT * FROM run_locations WHERE run_id = ? ORDER BY sequence ASC",
                        parameters: [runId],
                        mapper: { RunLocation(cursor: $0) }
                    ) {
                        let locations = rows.compactMap { $0 }
                        await send(.locationsLoaded(locations))
                    }
                }

            case .locationsLoaded(let locations):
                state.locations = locations
                state.isLoadingLocations = false
                return .none
            }
        }
    }
}

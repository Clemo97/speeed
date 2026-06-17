import ComposableArchitecture
import CoreLocation
import Foundation
import MapKit
import Supabase

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

    @Dependency(\.supabaseClient) var supabaseClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let runId = state.run.id
                return .run { send in
                    do {
                        let response = try await supabaseClient
                            .from("run_locations")
                            .select()
                            .eq("run_id", value: runId)
                            .order("sequence", ascending: true)
                            .execute()
                        let locations = try JSONDecoder.supabase.decode(
                            [RunLocation].self, from: response.data
                        )
                        await send(.locationsLoaded(locations))
                    } catch {
                        await send(.locationsLoaded([]))
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

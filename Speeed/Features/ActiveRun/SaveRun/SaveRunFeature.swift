import ComposableArchitecture
import CoreLocation
import Dependencies
import Foundation

@Reducer struct SaveRunFeature {
    @ObservableState struct State: Equatable {
        var userId: String
        var title: String = ""
        var isPublic: Bool = true
        var isLoading: Bool = false
        var errorMessage: String?

        // Run data passed from ActiveRunFeature
        let distanceMeters: Double
        let durationSeconds: TimeInterval
        let averagePaceSecondsPerKm: Double
        let coordinates: [CLLocationCoordinate2D]
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case saveTapped
        case discardTapped
        case saveSucceeded
        case saveFailed(String)
        case errorDismissed
    }

    @Dependency(\.powerSyncDatabase) var database
    @Dependency(\.uuid) var uuid
    @Dependency(\.date.now) var now

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .saveTapped:
                state.isLoading = true
                let run = buildRun(from: state)
                let locations = buildLocations(runId: run.id, coordinates: state.coordinates)
                return .run { send in
                    do {
                        try await saveRun(run, locations: locations)
                        await send(.saveSucceeded)
                    } catch {
                        await send(.saveFailed(error.localizedDescription))
                    }
                }

            case .discardTapped:
                return .none

            case .saveSucceeded:
                state.isLoading = false
                return .none

            case .saveFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .errorDismissed:
                state.errorMessage = nil
                return .none
            }
        }
    }

    // MARK: Helpers

    private func buildRun(from state: State) -> Run {
        let runId = uuid().uuidString
        return Run(
            id: runId,
            userId: state.userId,
            title: state.title.isEmpty ? nil : state.title,
            status: .completed,
            startTime: Date(timeIntervalSinceNow: -state.durationSeconds),
            endTime: now,
            distanceMeters: state.distanceMeters,
            durationSeconds: state.durationSeconds,
            averagePaceSecondsPerKm: state.averagePaceSecondsPerKm,
            isPublic: state.isPublic,
            encodedPolyline: encodePolyline(state.coordinates),
            createdAt: now
        )
    }

    private func buildLocations(runId: String, coordinates: [CLLocationCoordinate2D]) -> [RunLocation] {
        coordinates.enumerated().map { index, coord in
            RunLocation(
                id: uuid().uuidString,
                runId: runId,
                location: CLLocation(latitude: coord.latitude, longitude: coord.longitude),
                sequence: index
            )
        }
    }

    private func saveRun(_ run: Run, locations: [RunLocation]) async throws {
        try await database.writeTransaction { tx in
            // Insert the run
            try tx.execute(
                sql: """
                INSERT INTO runs (id, user_id, title, status, start_time, end_time,
                    distance_meters, duration_seconds, average_pace_seconds_per_km,
                    is_public, encoded_polyline, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                parameters: [
                    run.id, run.userId, run.title as Any,
                    run.status.rawValue,
                    ISO8601DateFormatter().string(from: run.startTime),
                    run.endTime.map { ISO8601DateFormatter().string(from: $0) } as Any,
                    run.distanceMeters, run.durationSeconds, run.averagePaceSecondsPerKm,
                    run.isPublic ? 1 : 0,
                    run.encodedPolyline as Any,
                    ISO8601DateFormatter().string(from: run.createdAt)
                ]
            )

            // Batch insert locations
            for loc in locations {
                try tx.execute(
                    sql: """
                    INSERT INTO run_locations (id, run_id, latitude, longitude, altitude, speed, sequence, recorded_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    parameters: [
                        loc.id, loc.runId,
                        loc.latitude, loc.longitude, loc.altitude, loc.speed,
                        loc.sequence,
                        ISO8601DateFormatter().string(from: loc.recordedAt)
                    ]
                )
            }
        }
    }
}

// MARK: - Google Encoded Polyline

/// Simple implementation of the Google Encoded Polyline Algorithm.
private func encodePolyline(_ coordinates: [CLLocationCoordinate2D]) -> String {
    guard !coordinates.isEmpty else { return "" }
    var result = ""
    var prevLat = 0
    var prevLng = 0

    for coord in coordinates {
        let lat = Int(round(coord.latitude * 1e5))
        let lng = Int(round(coord.longitude * 1e5))
        result += encodeValue(lat - prevLat)
        result += encodeValue(lng - prevLng)
        prevLat = lat
        prevLng = lng
    }
    return result
}

private func encodeValue(_ value: Int) -> String {
    var v = value < 0 ? ~(value << 1) : value << 1
    var encoded = ""
    while v >= 0x20 {
        encoded.append(Character(UnicodeScalar((0x20 | (v & 0x1F)) + 63)!))
        v >>= 5
    }
    encoded.append(Character(UnicodeScalar(v + 63)!))
    return encoded
}

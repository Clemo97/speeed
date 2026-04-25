import CoreLocation
import Foundation
import PowerSync

// MARK: - RunLocation

struct RunLocation: Codable, Equatable, Identifiable {
    let id: String
    let runId: String
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let speed: Double
    let sequence: Int
    let recordedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case runId = "run_id"
        case latitude
        case longitude
        case altitude
        case speed
        case sequence
        case recordedAt = "recorded_at"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Init from PowerSync row

extension RunLocation {
    init?(row: [String: Any]) {
        guard
            let id = row["id"] as? String,
            let runId = row["run_id"] as? String,
            let lat = row["latitude"] as? Double,
            let lon = row["longitude"] as? Double,
            let recordedAtStr = row["recorded_at"] as? String,
            let recordedAt = ISO8601DateFormatter().date(from: recordedAtStr)
        else { return nil }

        self.id = id
        self.runId = runId
        self.latitude = lat
        self.longitude = lon
        self.altitude = row["altitude"] as? Double ?? 0
        self.speed = row["speed"] as? Double ?? 0
        self.sequence = row["sequence"] as? Int ?? 0
        self.recordedAt = recordedAt
    }

    init?(cursor: SqlCursor) {
        guard
            let id = try? cursor.getString(name: "id"),
            let runId = try? cursor.getString(name: "run_id"),
            let lat = try? cursor.getDouble(name: "latitude"),
            let lon = try? cursor.getDouble(name: "longitude"),
            let recordedAtStr = try? cursor.getString(name: "recorded_at"),
            let recordedAt = ISO8601DateFormatter().date(from: recordedAtStr)
        else { return nil }

        self.id = id
        self.runId = runId
        self.latitude = lat
        self.longitude = lon
        self.altitude = (try? cursor.getDouble(name: "altitude")) ?? 0
        self.speed = (try? cursor.getDouble(name: "speed")) ?? 0
        self.sequence = (try? cursor.getInt(name: "sequence")) ?? 0
        self.recordedAt = recordedAt
    }

    init(id: String, runId: String, location: CLLocation, sequence: Int) {
        self.id = id
        self.runId = runId
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.altitude = location.altitude
        self.speed = max(location.speed, 0)
        self.sequence = sequence
        self.recordedAt = location.timestamp
    }

    var asDictionary: [String: Any] {
        [
            "id": id,
            "run_id": runId,
            "latitude": latitude,
            "longitude": longitude,
            "altitude": altitude,
            "speed": speed,
            "sequence": sequence,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
    }
}

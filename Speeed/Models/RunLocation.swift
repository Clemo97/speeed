import CoreLocation
import Foundation

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

// MARK: - Init from CLLocation

extension RunLocation {
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
}

// MARK: - Insert Dictionary

extension RunLocation {
    /// Converts to a dictionary suitable for Supabase inserts.
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

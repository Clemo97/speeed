import CoreLocation
import Foundation

// MARK: - Run

struct Run: Codable, Equatable, Identifiable {
    let id: String
    let userId: String
    let title: String?
    let status: RunStatus
    let startTime: Date
    let endTime: Date?
    let distanceMeters: Double
    let durationSeconds: Double
    let averagePaceSecondsPerKm: Double
    let isPublic: Bool
    let encodedPolyline: String?
    let createdAt: Date

    enum RunStatus: String, Codable, Equatable {
        case active = "active"
        case completed = "completed"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case status
        case startTime = "start_time"
        case endTime = "end_time"
        case distanceMeters = "distance_meters"
        case durationSeconds = "duration_seconds"
        case averagePaceSecondsPerKm = "average_pace_seconds_per_km"
        case isPublic = "is_public"
        case encodedPolyline = "encoded_polyline"
        case createdAt = "created_at"
    }
}

// MARK: - Computed Properties

extension Run {
    /// Formatted duration as "HH:MM:SS" or "MM:SS"
    var formattedDuration: String {
        let total = Int(durationSeconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Formatted distance e.g. "5.24 km"
    var formattedDistance: String {
        let km = distanceMeters / 1000
        return String(format: "%.2f km", km)
    }

    /// Formatted pace e.g. "5:30 /km"
    var formattedPace: String {
        let minutes = Int(averagePaceSecondsPerKm) / 60
        let seconds = Int(averagePaceSecondsPerKm) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
}

// MARK: - Insert Dictionary

extension Run {
    /// Converts the Run to a dictionary suitable for Supabase inserts.
    /// Dates are ISO 8601 strings; booleans are native Bool values.
    var asDictionary: [String: Any] {
        let formatter = ISO8601DateFormatter()
        var dict: [String: Any] = [
            "id": id,
            "user_id": userId,
            "status": status.rawValue,
            "start_time": formatter.string(from: startTime),
            "distance_meters": distanceMeters,
            "duration_seconds": durationSeconds,
            "average_pace_seconds_per_km": averagePaceSecondsPerKm,
            "is_public": isPublic,
            "created_at": formatter.string(from: createdAt)
        ]
        if let title { dict["title"] = title }
        if let endTime { dict["end_time"] = formatter.string(from: endTime) }
        if let encodedPolyline { dict["encoded_polyline"] = encodedPolyline }
        return dict
    }
}

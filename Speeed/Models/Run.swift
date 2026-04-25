import CoreLocation
import Foundation
import PowerSync

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

// MARK: - Init from PowerSync row

extension Run {
    /// Convenience init from a raw PowerSync row dictionary.
    init?(row: [String: Any]) {
        guard
            let id = row["id"] as? String,
            let userId = row["user_id"] as? String,
            let statusRaw = row["status"] as? String,
            let status = RunStatus(rawValue: statusRaw),
            let startTimeStr = row["start_time"] as? String,
            let startTime = ISO8601DateFormatter().date(from: startTimeStr)
        else { return nil }

        self.id = id
        self.userId = userId
        self.title = row["title"] as? String
        self.status = status
        self.startTime = startTime
        self.endTime = (row["end_time"] as? String).flatMap { ISO8601DateFormatter().date(from: $0) }
        self.distanceMeters = row["distance_meters"] as? Double ?? 0
        self.durationSeconds = row["duration_seconds"] as? Double ?? 0
        self.averagePaceSecondsPerKm = row["average_pace_seconds_per_km"] as? Double ?? 0
        self.isPublic = (row["is_public"] as? Int ?? 1) == 1
        self.encodedPolyline = row["encoded_polyline"] as? String
        self.createdAt = (row["created_at"] as? String).flatMap { ISO8601DateFormatter().date(from: $0) } ?? startTime
    }

    /// Init from a PowerSync SqlCursor (typed, avoids type-coercion ambiguity).
    init?(cursor: SqlCursor) {
        guard
            let id = try? cursor.getString(name: "id"),
            let userId = try? cursor.getString(name: "user_id"),
            let statusRaw = try? cursor.getString(name: "status"),
            let status = RunStatus(rawValue: statusRaw),
            let startTimeStr = try? cursor.getString(name: "start_time"),
            let startTime = ISO8601DateFormatter().date(from: startTimeStr)
        else { return nil }

        self.id = id
        self.userId = userId
        self.title = try? cursor.getString(name: "title")
        self.status = status
        self.startTime = startTime
        self.endTime = (try? cursor.getString(name: "end_time")).flatMap { ISO8601DateFormatter().date(from: $0) }
        self.distanceMeters = (try? cursor.getDouble(name: "distance_meters")) ?? 0
        self.durationSeconds = (try? cursor.getDouble(name: "duration_seconds")) ?? 0
        self.averagePaceSecondsPerKm = (try? cursor.getDouble(name: "average_pace_seconds_per_km")) ?? 0
        self.isPublic = ((try? cursor.getInt(name: "is_public")) ?? 1) != 0
        self.encodedPolyline = try? cursor.getString(name: "encoded_polyline")
        self.createdAt = (try? cursor.getString(name: "created_at")).flatMap { ISO8601DateFormatter().date(from: $0) } ?? startTime
    }

    /// Convert to a dictionary for PowerSync writes.
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
            "is_public": isPublic ? 1 : 0,
            "created_at": formatter.string(from: createdAt)
        ]
        if let title { dict["title"] = title }
        if let endTime { dict["end_time"] = formatter.string(from: endTime) }
        if let encodedPolyline { dict["encoded_polyline"] = encodedPolyline }
        return dict
    }
}

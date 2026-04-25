import Foundation
import PowerSync

// MARK: - Profile

struct Profile: Codable, Equatable, Identifiable {
    let id: String
    let username: String
    let displayName: String?
    let avatarUrl: String?
    let bio: String?
    let isPublic: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case bio
        case isPublic = "is_public"
        case createdAt = "created_at"
    }
}

extension Profile {
    init?(row: [String: Any]) {
        guard
            let id = row["id"] as? String,
            let username = row["username"] as? String
        else { return nil }

        self.id = id
        self.username = username
        self.displayName = row["display_name"] as? String
        self.avatarUrl = row["avatar_url"] as? String
        self.bio = row["bio"] as? String
        self.isPublic = (row["is_public"] as? Int ?? 1) == 1
        self.createdAt = (row["created_at"] as? String).flatMap {
            ISO8601DateFormatter().date(from: $0)
        } ?? Date()
    }

    var displayTitle: String {
        displayName ?? username
    }

    init?(cursor: SqlCursor) {
        guard
            let id = try? cursor.getString(name: "id"),
            let username = try? cursor.getString(name: "username")
        else { return nil }

        self.id = id
        self.username = username
        self.displayName = try? cursor.getString(name: "display_name")
        self.avatarUrl = try? cursor.getString(name: "avatar_url")
        self.bio = try? cursor.getString(name: "bio")
        self.isPublic = ((try? cursor.getInt(name: "is_public")) ?? 1) != 0
        self.createdAt = (try? cursor.getString(name: "created_at")).flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
    }
}

// MARK: - Follow

struct Follow: Codable, Equatable, Identifiable {
    let id: String
    let followerId: String
    let followingId: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case followerId = "follower_id"
        case followingId = "following_id"
        case createdAt = "created_at"
    }
}

extension Follow {
    init?(row: [String: Any]) {
        guard
            let id = row["id"] as? String,
            let followerId = row["follower_id"] as? String,
            let followingId = row["following_id"] as? String
        else { return nil }

        self.id = id
        self.followerId = followerId
        self.followingId = followingId
        self.createdAt = (row["created_at"] as? String).flatMap {
            ISO8601DateFormatter().date(from: $0)
        } ?? Date()
    }
}

// MARK: - Kudos

struct Kudos: Codable, Equatable, Identifiable {
    let id: String
    let runId: String
    let userId: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case runId = "run_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

// MARK: - Notification

struct AppNotification: Codable, Equatable, Identifiable {
    let id: String
    let userId: String
    let actorId: String
    let type: NotificationType
    let entityId: String
    let isRead: Bool
    let createdAt: Date

    enum NotificationType: String, Codable, Equatable {
        case kudos = "kudos"
        case newFollower = "new_follower"
        case segmentRecord = "segment_record"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case actorId = "actor_id"
        case type = "type"
        case entityId = "entity_id"
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

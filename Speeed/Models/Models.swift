import Foundation

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

    var displayTitle: String {
        displayName ?? username
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

import PowerSync

// MARK: - Tables
// id column is automatically included by PowerSync — never declare it.

let profilesTable = Table(
    name: "profiles",
    columns: [
        .text("username"),
        .text("display_name"),
        .text("avatar_url"),
        .text("bio"),
        .integer("is_public"),     // 0 or 1
        .text("created_at"),
        .text("updated_at")
    ]
)

let runsTable = Table(
    name: "runs",
    columns: [
        .text("user_id"),
        .text("title"),
        .text("status"),           // "active" | "completed"
        .text("start_time"),
        .text("end_time"),
        .real("distance_meters"),
        .real("duration_seconds"),
        .real("average_pace_seconds_per_km"),
        .integer("is_public"),     // 0 or 1
        .text("encoded_polyline"),
        .text("created_at")
    ],
    indexes: [
        Index(name: "user_id", columns: [IndexedColumn.ascending("user_id")]),
        Index(name: "start_time", columns: [IndexedColumn.descending("start_time")])
    ]
)

let runLocationsTable = Table(
    name: "run_locations",
    columns: [
        .text("run_id"),
        .real("latitude"),
        .real("longitude"),
        .real("altitude"),
        .real("speed"),
        .integer("sequence"),
        .text("recorded_at")
    ],
    indexes: [
        Index(name: "run_id_sequence", columns: [
            IndexedColumn.ascending("run_id"),
            IndexedColumn.ascending("sequence")
        ])
    ]
)

let followsTable = Table(
    name: "follows",
    columns: [
        .text("follower_id"),
        .text("following_id"),
        .text("created_at")
    ],
    indexes: [
        Index(name: "follower_id", columns: [IndexedColumn.ascending("follower_id")])
    ]
)

let kudosTable = Table(
    name: "kudos",
    columns: [
        .text("run_id"),
        .text("user_id"),
        .text("created_at")
    ],
    indexes: [
        Index(name: "run_id", columns: [IndexedColumn.ascending("run_id")])
    ]
)

let segmentsTable = Table(
    name: "segments",
    columns: [
        .text("creator_id"),
        .text("name"),
        .text("encoded_polyline"),
        .real("distance_meters"),
        .text("created_at")
    ]
)

let segmentEffortsTable = Table(
    name: "segment_efforts",
    columns: [
        .text("segment_id"),
        .text("run_id"),
        .text("user_id"),
        .real("elapsed_seconds"),
        .text("recorded_at")
    ],
    indexes: [
        Index(name: "segment_id", columns: [IndexedColumn.ascending("segment_id")])
    ]
)

let notificationsTable = Table(
    name: "notifications",
    columns: [
        .text("user_id"),
        .text("actor_id"),
        .text("type"),           // "kudos" | "new_follower" | "segment_record"
        .text("entity_id"),
        .integer("is_read"),     // 0 or 1
        .text("created_at")
    ],
    indexes: [
        Index(name: "user_id_read", columns: [
            IndexedColumn.ascending("user_id"),
            IndexedColumn.ascending("is_read")
        ])
    ]
)

// MARK: - App Schema

let AppSchema = Schema(tables: [
    profilesTable,
    runsTable,
    runLocationsTable,
    followsTable,
    kudosTable,
    segmentsTable,
    segmentEffortsTable,
    notificationsTable
])

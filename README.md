# Speeed

A GPS running tracker for iOS and iPadOS, built with offline-first sync. Track distance, pace, and route. Follow friends, give kudos, and compete on segments.

## Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 17+) |
| State management | [Composable Architecture (TCA)](https://github.com/pointfreeco/swift-composable-architecture) 1.15+ |
| Backend | [Supabase](https://supabase.com) (Postgres + Auth + Storage) |
| Offline sync | [PowerSync](https://www.powersync.com) Cloud (Sync Streams, Edition 3) |
| Location | `CLLocationUpdate.liveUpdates(.fitness)` (iOS 17 native AsyncSequence) |
| Maps | SwiftUI `Map` + `MapPolyline` (no UIViewRepresentable) |
| Project generation | [XcodeGen](https://github.com/yonaskolb/XcodeGen) |

## Features

- GPS run tracking with live map, pace, and distance
- Run history with per-km splits and route replay
- Social feed from followed users
- Kudos on runs
- Segments and leaderboards
- Push notifications (follow + kudos events)
- Full offline support — all reads/writes work without network, sync resumes automatically

## Project Structure

```
Speeed/
├── App/                    # Root reducer + entry point
├── Configuration/          # Supabase + PowerSync URLs (gitignored)
├── Database/               # PowerSync schema + Supabase connector
├── Dependencies/           # TCA dependency registrations
├── Features/
│   ├── Auth/               # Login (Apple, Google, email) + Register
│   ├── AppTabs/            # Tab container
│   ├── Dashboard/          # Weekly stats + recent runs
│   ├── Record/             # Pre-run screen
│   ├── ActiveRun/          # Live GPS tracking + save flow
│   ├── RunHistory/         # Run list + detail with splits
│   ├── Feed/               # Social feed
│   └── Profile/            # Own profile, stats, sign out
├── Models/                 # Run, RunLocation, Profile, Follow, Kudos
supabase/
└── migrations/             # Schema, RLS policies, triggers + publication
powersync/
└── sync-config.yaml        # Sync Streams config (Edition 3, 12 streams)
project.yml                 # XcodeGen config
```

## Getting Started

### Prerequisites

- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- A [Supabase](https://supabase.com) project
- A [PowerSync Cloud](https://www.powersync.com) instance connected to your Supabase Postgres

### 1. Clone and configure

```bash
git clone https://github.com/Clemo97/speeed.git
cd speeed

# Copy the config template and fill in your values
cp Speeed/Configuration/Configuration.example.swift Speeed/Configuration/Configuration.swift
```

Edit `Speeed/Configuration/Configuration.swift`:

```swift
enum Configuration {
    static let supabaseURL = "https://YOUR_PROJECT_REF.supabase.co"
    static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
    static let powerSyncURL = "https://YOUR_INSTANCE_ID.powersync.journeyapps.com"
}
```

Values are available from:
- **Supabase**: Project Settings → API
- **PowerSync**: Dashboard → your instance → Connection Details

### 2. Apply database migrations

```bash
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

This applies:
- `20260424000000` — 8 tables (profiles, runs, run_locations, follows, kudos, segments, segment_efforts, notifications)
- `20260424000001` — RLS policies on all tables
- `20260424000002` — triggers (new user profile, notifications) + `powersync` publication

### 3. Configure PowerSync

In the [PowerSync Dashboard](https://dashboard.powersync.com):

1. Create a new instance and connect your Supabase Postgres database
2. Under **Client Auth**, enable **Use Supabase Auth** (leave JWT Secret empty — RS256 is auto-detected)
3. Under **Sync Rules**, paste the contents of `powersync/sync-config.yaml` and deploy

### 4. Enable Auth providers

In the Supabase Dashboard → Authentication → Providers:
- Enable **Apple** (requires an Apple Developer account with Sign In with Apple capability)
- Enable **Google** (requires a Google Cloud OAuth client ID)

### 5. Generate and open the Xcode project

```bash
xcodegen generate
open Speeed.xcodeproj
```

Set your Development Team in Xcode (Signing & Capabilities), then build and run on a device (location tracking requires real hardware).

## Architecture

The app uses TCA with `@Reducer`, `@ObservableState`, and `@Dependency` throughout. Navigation uses `StackState`/`StackActionOf` for push flows and `@Presents` for sheets.

PowerSync is the local SQLite layer — all reads go through `db.watch(sql:parameters:mapper:)` which returns an `AsyncThrowingStream` that updates live as data changes. Writes go through `db.writeTransaction` and are queued for upload to Supabase via the `SupabasePowerSyncConnector`.

```
View → Store.send(action)
          ↓
       Reducer
          ↓ effect
    db.watch() / db.writeTransaction()
          ↓
     SQLite (local)
          ↓ background sync
     PowerSync Cloud
          ↓ replication
       Supabase Postgres
```

## Sync Streams

12 streams across 3 priority tiers ensure the app renders immediately on launch:

| Priority | Streams |
|---|---|
| 1 | `my_profile` |
| 2 | `my_runs`, `my_run_locations`, `my_follows`, `my_notifications`, `my_kudos`, `my_segment_efforts` |
| 3 | `network_profiles`, `network_runs`, `network_kudos`, `network_segment_efforts`, `segments` |

## License

MIT

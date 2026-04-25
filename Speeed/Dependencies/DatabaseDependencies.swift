import Dependencies
import Foundation
import PowerSync
import Supabase

// MARK: - Supabase Client Dependency

extension SupabaseClient: @retroactive DependencyKey {
    public static var liveValue: SupabaseClient {
        SupabaseClient(
            supabaseURL: URL(string: Configuration.supabaseURL)!,
            supabaseKey: Configuration.supabaseAnonKey
        )
    }
}

extension DependencyValues {
    var supabaseClient: SupabaseClient {
        get { self[SupabaseClient.self] }
        set { self[SupabaseClient.self] = newValue }
    }
}

// MARK: - PowerSync Database Dependency

enum PowerSyncDatabaseKey: DependencyKey {
    static var liveValue: any PowerSyncDatabaseProtocol {
        PowerSyncDatabase(
            schema: AppSchema,
            dbFilename: "speeed.sqlite"
        )
    }
}

extension DependencyValues {
    var powerSyncDatabase: any PowerSyncDatabaseProtocol {
        get { self[PowerSyncDatabaseKey.self] }
        set { self[PowerSyncDatabaseKey.self] = newValue }
    }
}

// MARK: - Connector Dependency

enum ConnectorKey: DependencyKey {
    @MainActor
    static var liveValue: SupabasePowerSyncConnector {
        @Dependency(\.supabaseClient) var supabaseClient
        return SupabasePowerSyncConnector(supabaseClient: supabaseClient)
    }
}

extension DependencyValues {
    var connector: SupabasePowerSyncConnector {
        get { self[ConnectorKey.self] }
        set { self[ConnectorKey.self] = newValue }
    }
}

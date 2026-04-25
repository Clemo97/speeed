import Foundation
import PowerSync
import Supabase

// MARK: - Supabase + PowerSync Connector

@Observable
@MainActor
final class SupabasePowerSyncConnector: PowerSyncBackendConnectorProtocol {
    private let supabaseClient: SupabaseClient

    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }

    // MARK: Fetch Credentials
    // Called automatically by PowerSync whenever it needs a fresh token.
    // Always return a live token from the current Supabase session — never cache.

    func fetchCredentials() async throws -> PowerSyncCredentials? {
        let session = try await supabaseClient.auth.session
        return PowerSyncCredentials(
            endpoint: Configuration.powerSyncURL,
            token: session.accessToken
        )
    }

    // MARK: Upload Data
    // Drains the local CRUD queue and syncs mutations up to Supabase.
    // Called automatically by PowerSync after local writes.

    func uploadData(database: any PowerSyncDatabaseProtocol) async throws {
        guard let transaction = try await database.getNextCrudTransaction() else { return }

        do {
            for entry in transaction.crud {
                switch entry.op {
                case .put:
                    var data = entry.opData ?? [:]
                    data["id"] = entry.id
                    let json = try toAnyJSON(data)
                    try await supabaseClient.from(entry.table).upsert(json).execute()

                case .patch:
                    guard let opData = entry.opData else { continue }
                    let json = try toAnyJSON(opData)
                    try await supabaseClient
                        .from(entry.table)
                        .update(json)
                        .eq("id", value: entry.id)
                        .execute()

                case .delete:
                    try await supabaseClient
                        .from(entry.table)
                        .delete()
                        .eq("id", value: entry.id)
                        .execute()
                }
            }
            try await transaction.complete()
        } catch {
            // Re-throw so PowerSync can retry on transient failures
            throw error
        }
    }

    // MARK: Helpers

    private func toAnyJSON(_ dict: [String: Any]) throws -> [String: AnyJSON] {
        let data = try JSONSerialization.data(withJSONObject: dict)
        return try JSONDecoder().decode([String: AnyJSON].self, from: data)
    }
}

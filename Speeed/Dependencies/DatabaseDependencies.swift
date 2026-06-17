import Dependencies
import Foundation
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

// MARK: - JSON Decoder for Supabase responses

extension JSONDecoder {
    /// Decoder configured to handle Supabase's ISO 8601 timestamps,
    /// including fractional seconds (e.g. 2026-06-16T15:34:50.123456+00:00).
    static let supabase: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: string) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(string)"
            )
        }
        return decoder
    }()
}

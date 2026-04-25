import CoreLocation
import Dependencies
import Foundation

// MARK: - Location Client

struct LocationClient: Sendable {
    var liveUpdates: @Sendable () -> AsyncThrowingStream<CLLocationUpdate, Error>
    var requestWhenInUseAuthorization: @Sendable () -> Void
}

// MARK: - Dependency Registration

extension LocationClient: DependencyKey {
    static var liveValue: LocationClient {
        LocationClient(
            liveUpdates: {
                AsyncThrowingStream { continuation in
                    let task = Task {
                        do {
                            for try await update in CLLocationUpdate.liveUpdates(.fitness) {
                                continuation.yield(update)
                            }
                            continuation.finish()
                        } catch {
                            continuation.finish(throwing: error)
                        }
                    }
                    continuation.onTermination = { _ in task.cancel() }
                }
            },
            requestWhenInUseAuthorization: {
                // Authorization is requested automatically by CLLocationUpdate.liveUpdates
                // when the user starts a run. This is a no-op since NSLocationWhenInUseUsageDescription
                // is set in Info.plist and liveUpdates handles the prompt.
            }
        )
    }

    static var testValue: LocationClient {
        LocationClient(
            liveUpdates: {
                AsyncThrowingStream { continuation in
                    continuation.finish()
                }
            },
            requestWhenInUseAuthorization: {}
        )
    }
}

extension DependencyValues {
    var locationClient: LocationClient {
        get { self[LocationClient.self] }
        set { self[LocationClient.self] = newValue }
    }
}

import ComposableArchitecture
import Foundation

@Reducer(state: .equatable) enum FeedPath {
    case runDetail(RunDetailFeature)
}

@Reducer struct FeedFeature {
    @ObservableState struct State: Equatable {
        var userId: String
        var path = StackState<FeedPath.State>()
        var runs: [Run] = []
        var isLoading = false
    }

    enum Action {
        case path(StackActionOf<FeedPath>)
        case onAppear
        case feedUpdated([Run])
        case runRowTapped(Run)
    }

    @Dependency(\.powerSyncDatabase) var database

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isLoading else { return .none }
                state.isLoading = true
                let userId = state.userId
                return .run { send in
                    // Watch runs from users that the current user follows (synced by PowerSync
                    // via the network_runs stream), plus own runs, sorted by recency.
                    for try await rows in try database.watch(
                        sql: """
                        SELECT r.* FROM runs r
                        WHERE r.status = 'completed'
                          AND r.is_public = 1
                          AND (
                            r.user_id = ?
                            OR r.user_id IN (
                              SELECT following_id FROM follows WHERE follower_id = ?
                            )
                          )
                        ORDER BY r.start_time DESC
                        LIMIT 50
                        """,
                        parameters: [userId, userId],
                        mapper: { Run(cursor: $0) }
                    ) {
                        let runs = rows.compactMap { $0 }
                        await send(.feedUpdated(runs))
                    }
                }

            case .feedUpdated(let runs):
                state.runs = runs
                state.isLoading = false
                return .none

            case .runRowTapped(let run):
                state.path.append(.runDetail(RunDetailFeature.State(run: run)))
                return .none

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path) {
            FeedPath.body
        }
    }
}

import ComposableArchitecture
import Foundation

@Reducer(state: .equatable) enum DashboardPath {
    case runDetail(RunDetailFeature)
}

@Reducer struct DashboardFeature {
    @ObservableState struct State: Equatable {
        var userId: String
        var path = StackState<DashboardPath.State>()
        var recentRuns: [Run] = []
        var weeklyDistanceMeters: Double = 0
        var weeklyRunCount: Int = 0
        var isLoading = false
    }

    enum Action {
        case path(StackActionOf<DashboardPath>)
        case onAppear
        case recentRunsUpdated([Run])
        case runRowTapped(Run)
    }

    @Dependency(\.powerSyncDatabase) var database
    @Dependency(\.date.now) var now

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isLoading else { return .none }
                state.isLoading = true
                let userId = state.userId
                return .run { send in
                    for try await rows in try database.watch(
                        sql: """
                        SELECT * FROM runs
                        WHERE user_id = ? AND status = 'completed'
                        ORDER BY start_time DESC
                        LIMIT 5
                        """,
                        parameters: [userId],
                        mapper: { Run(cursor: $0) }
                    ) {
                        let runs = rows.compactMap { $0 }
                        await send(.recentRunsUpdated(runs))
                    }
                }

            case .recentRunsUpdated(let runs):
                state.recentRuns = runs
                state.isLoading = false
                // Compute weekly stats (last 7 days)
                let cutoff = now.addingTimeInterval(-7 * 24 * 3600)
                let weeklyRuns = runs.filter { $0.startTime >= cutoff }
                state.weeklyRunCount = weeklyRuns.count
                state.weeklyDistanceMeters = weeklyRuns.reduce(0) { $0 + $1.distanceMeters }
                return .none

            case .runRowTapped(let run):
                state.path.append(.runDetail(RunDetailFeature.State(run: run)))
                return .none

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path) {
            DashboardPath.body
        }
    }
}

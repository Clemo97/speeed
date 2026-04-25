import ComposableArchitecture
import Foundation

@Reducer(state: .equatable) enum RunHistoryPath {
    case runDetail(RunDetailFeature)
}

@Reducer struct RunHistoryFeature {
    @ObservableState struct State: Equatable {
        var userId: String
        var path = StackState<RunHistoryPath.State>()
        var runs: [Run] = []
        var isLoading = false
    }

    enum Action {
        case path(StackActionOf<RunHistoryPath>)
        case onAppear
        case runsUpdated([Run])
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
                    for try await rows in try database.watch(
                        sql: "SELECT * FROM runs WHERE user_id = ? AND status = 'completed' ORDER BY start_time DESC",
                        parameters: [userId],
                        mapper: { Run(cursor: $0) }
                    ) {
                        let runs = rows.compactMap { $0 }
                        await send(.runsUpdated(runs))
                    }
                }

            case .runsUpdated(let runs):
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
            RunHistoryPath.body
        }
    }
}

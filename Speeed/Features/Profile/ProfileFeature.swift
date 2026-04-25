import ComposableArchitecture
import Foundation

@Reducer(state: .equatable) enum ProfilePath {
    case runDetail(RunDetailFeature)
}

@Reducer struct ProfileFeature {
    @ObservableState struct State: Equatable {
        var userId: String
        var path = StackState<ProfilePath.State>()
        var profile: Profile?
        var runs: [Run] = []
        var isLoading = false
    }

    enum Action {
        case path(StackActionOf<ProfilePath>)
        case onAppear
        case profileUpdated(Profile?)
        case runsUpdated([Run])
        case runRowTapped(Run)
        case signOutTapped
    }

    @Dependency(\.powerSyncDatabase) var database
    @Dependency(\.supabaseClient) var supabaseClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isLoading else { return .none }
                state.isLoading = true
                let userId = state.userId
                return .merge(
                    watchProfile(userId: userId),
                    watchRuns(userId: userId)
                )

            case .profileUpdated(let profile):
                state.profile = profile
                state.isLoading = false
                return .none

            case .runsUpdated(let runs):
                state.runs = runs
                return .none

            case .runRowTapped(let run):
                state.path.append(.runDetail(RunDetailFeature.State(run: run)))
                return .none

            case .signOutTapped:
                return .run { _ in
                    try? await supabaseClient.auth.signOut()
                }

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path) {
            ProfilePath.body
        }
    }

    private func watchProfile(userId: String) -> Effect<Action> {
        .run { send in
            for try await rows in try database.watch(
                sql: "SELECT * FROM profiles WHERE id = ? LIMIT 1",
                parameters: [userId],
                mapper: { Profile(cursor: $0) }
            ) {
                let profile = rows.first.flatMap { $0 }
                await send(.profileUpdated(profile))
            }
        }
    }

    private func watchRuns(userId: String) -> Effect<Action> {
        .run { send in
            for try await rows in try database.watch(
                sql: "SELECT * FROM runs WHERE user_id = ? AND status = 'completed' ORDER BY start_time DESC",
                parameters: [userId],
                mapper: { Run(cursor: $0) }
            ) {
                let runs = rows.compactMap { $0 }
                await send(.runsUpdated(runs))
            }
        }
    }
}

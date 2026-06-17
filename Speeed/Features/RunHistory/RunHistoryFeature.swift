import ComposableArchitecture
import Foundation
import Supabase

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
        case runsLoaded([Run])
        case runRowTapped(Run)
    }

    @Dependency(\.supabaseClient) var supabaseClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isLoading else { return .none }
                state.isLoading = true
                let userId = state.userId
                return .run { send in
                    do {
                        let response = try await supabaseClient
                            .from("runs")
                            .select()
                            .eq("user_id", value: userId)
                            .eq("status", value: "completed")
                            .order("start_time", ascending: false)
                            .execute()
                        let runs = try JSONDecoder.supabase.decode([Run].self, from: response.data)
                        await send(.runsLoaded(runs))
                    } catch {
                        await send(.runsLoaded([]))
                    }
                }

            case .runsLoaded(let runs):
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

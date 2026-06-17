import ComposableArchitecture
import Foundation
import Supabase

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
        case runsLoaded([Run])
        case runRowTapped(Run)
    }

    @Dependency(\.supabaseClient) var supabaseClient
    @Dependency(\.date.now) var now

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
                            .limit(50)
                            .execute()
                        let runs = try JSONDecoder.supabase.decode([Run].self, from: response.data)
                        await send(.runsLoaded(runs))
                    } catch {
                        await send(.runsLoaded([]))
                    }
                }

            case .runsLoaded(let runs):
                state.isLoading = false
                // Show 5 most recent runs
                state.recentRuns = Array(runs.prefix(5))
                // Compute weekly stats from all fetched runs
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

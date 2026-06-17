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
        var yearlyDistanceMeters: Double = 0
        var yearlyRunCount: Int = 0
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
                // Compute yearly stats from all fetched runs
                let year = Calendar.current.component(.year, from: now)
                let startOfYear = Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1)) ?? now
                let yearlyRuns = runs.filter { $0.startTime >= startOfYear }
                state.yearlyRunCount = yearlyRuns.count
                state.yearlyDistanceMeters = yearlyRuns.reduce(0) { $0 + $1.distanceMeters }
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

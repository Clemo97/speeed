import ComposableArchitecture
import Foundation
import Supabase

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
        case profileLoaded(Profile?)
        case runsLoaded([Run])
        case runRowTapped(Run)
        case signOutTapped
    }

    @Dependency(\.supabaseClient) var supabaseClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isLoading else { return .none }
                state.isLoading = true
                let userId = state.userId
                return .merge(
                    fetchProfile(userId: userId),
                    fetchRuns(userId: userId)
                )

            case .profileLoaded(let profile):
                state.profile = profile
                state.isLoading = false
                return .none

            case .runsLoaded(let runs):
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

    private func fetchProfile(userId: String) -> Effect<Action> {
        .run { send in
            do {
                let response = try await supabaseClient
                    .from("profiles")
                    .select()
                    .eq("id", value: userId)
                    .limit(1)
                    .execute()
                let profiles = try JSONDecoder.supabase.decode([Profile].self, from: response.data)
                await send(.profileLoaded(profiles.first))
            } catch {
                await send(.profileLoaded(nil))
            }
        }
    }

    private func fetchRuns(userId: String) -> Effect<Action> {
        .run { send in
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
    }
}

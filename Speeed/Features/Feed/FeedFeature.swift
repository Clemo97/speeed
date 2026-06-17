import ComposableArchitecture
import Foundation
import Supabase

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
        case feedLoaded([Run])
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
                        // Step 1: fetch the list of users this person follows
                        let followsResponse = try await supabaseClient
                            .from("follows")
                            .select("following_id")
                            .eq("follower_id", value: userId)
                            .execute()

                        struct FollowingRow: Decodable { let following_id: String }
                        let followingRows = try JSONDecoder().decode(
                            [FollowingRow].self, from: followsResponse.data
                        )
                        let followingIds = followingRows.map { $0.following_id }

                        // Step 2: fetch public completed runs from own user + followed users
                        let allUserIds = [userId] + followingIds
                        let runsResponse = try await supabaseClient
                            .from("runs")
                            .select()
                            .in("user_id", values: allUserIds)
                            .eq("status", value: "completed")
                            .eq("is_public", value: true)
                            .order("start_time", ascending: false)
                            .limit(50)
                            .execute()
                        let runs = try JSONDecoder.supabase.decode([Run].self, from: runsResponse.data)
                        await send(.feedLoaded(runs))
                    } catch {
                        await send(.feedLoaded([]))
                    }
                }

            case .feedLoaded(let runs):
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

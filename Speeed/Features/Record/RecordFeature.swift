import ComposableArchitecture
import Foundation

@Reducer struct RecordFeature {
    @ObservableState struct State: Equatable {
        var userId: String
        @Presents var activeRun: ActiveRunFeature.State?
    }

    enum Action {
        case activeRun(PresentationAction<ActiveRunFeature.Action>)
        case startRunTapped
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .startRunTapped:
                state.activeRun = ActiveRunFeature.State(userId: state.userId)
                return .none
            case .activeRun:
                return .none
            }
        }
        .ifLet(\.$activeRun, action: \.activeRun) {
            ActiveRunFeature()
        }
    }
}

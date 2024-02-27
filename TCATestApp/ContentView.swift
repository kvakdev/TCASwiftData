//
//  ContentView.swift
//  TCATestApp
//
//  Created by Andrii Kvashuk on 19/02/2024.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct AppFeature {
    
    @ObservableState
    struct State: Equatable {
        let title: String
        @Presents var destination: Destination.State?
        
        init(title: String, destination: Destination.State?) {
            self.destination = destination
            self.title = title
        }
    }
    
    @CasePathable
    enum Action {
        case destination(PresentationAction<Destination.Action>)
    }
    
//    @Reducer
//    struct Destination {
//        enum State: Equatable {
//            case home(HomeFeature.State)
//        }
//        enum Action {
//            case home(HomeFeature.Action)
//        }
//        
//        var body: some ReducerOf<Self> {
//            Reduce<State, Action> { state, action in
//                return .none
//            }
//        }
//    }
    @Reducer(state: .equatable)
    enum Destination {
        case home(HomeFeature)
    }
    
    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            return .none
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

struct ContentView: View {
    @Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        IfLetStore(self.store.scope(state: \.destination, action: \.destination)) { store in
            SwitchStore(store) { state in
                switch state {
                case .home(let homeState):
                    HomeFeatureView(store: Store(initialState: homeState, reducer: { HomeFeature() }))
                }
            }
        } else: {
            Color.orange
        }
    }
}
//
//#Preview {
//    ContentView(store: Store(initialState: .init(title: "Preview Hello World",
//                                                 destination: AppFeature.Destination.State.home(
//                                                    HomeFeature.State()
//                                                 )),
//                             reducer: { AppFeature() }
//                            ))
//}

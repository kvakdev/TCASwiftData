//
//  HomeFeature.swift
//  TCATestApp
//
//  Created by Andrii Kvashuk on 20/02/2024.
//

import SwiftUI

import ComposableArchitecture

@Reducer
struct HomeFeature {
    
    @ObservableState
    struct State: Equatable {
        let tabs: [Tabs] = [.one, .two, .three]
        var booksContainerState: BookListContainerFeature.State = .init()
        var selectedTab: Tabs = .two
    }
    
    enum Tabs: Equatable {
        case one
        case two
        case three
    }
    
    enum Action: Equatable {
        case selectedTabChanged(tab: Tabs)
        case bookListContainer(BookListContainerFeature.Action)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.booksContainerState, action: \.bookListContainer) {
            BookListContainerFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .selectedTabChanged(let tab):
                state.selectedTab = tab
                return .none
            case .bookListContainer(let listAction):
                return .none
            }
        }
        ._printChanges()
    }
}

struct HomeFeatureView: View {
    @Bindable var store: StoreOf<HomeFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            TabView(selection: viewStore.binding(get: \.selectedTab,
                                                 send: { .selectedTabChanged(tab: $0) } )) {
                BookListContainerView(store: store.scope(state: \.booksContainerState, action: \.bookListContainer))
                .tag(HomeFeature.Tabs.one)
                .tabItem { Text("Books") }
                
                Text("Two")
                    .tag(HomeFeature.Tabs.two)
                    .tabItem { Text("Two") }
                Text("Three")
                    .tag(HomeFeature.Tabs.three)
                    .tabItem { Text("Three") }
            }
        }
    }
}

#Preview {
    HomeFeatureView(store: Store(initialState: .init(), reducer: { HomeFeature() }))
}

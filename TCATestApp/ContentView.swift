//
//  ContentView.swift
//  TCATestApp
//
//  Created by Andrii Kvashuk on 19/02/2024.
//

import SwiftUI
import ComposableArchitecture

struct AppFeature: Reducer {
    struct State {}
    enum Action {}
    
    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            return .none
        }
    }
}

struct ContentView: View {
    
    let store: StoreOf<AppFeature>
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView(store: Store(initialState: .init(),
                             reducer: { AppFeature() }
                            ))
}

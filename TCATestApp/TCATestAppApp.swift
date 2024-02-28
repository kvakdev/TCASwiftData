//
//  TCATestAppApp.swift
//  TCATestApp
//
//  Created by Andrii Kvashuk on 19/02/2024.
//

import SwiftUI
import ComposableArchitecture
import SwiftData

@main
struct TCATestAppApp: App {
    @Dependency(\.appContainer) var container: ModelContainer
    
    var body: some Scene {
        WindowGroup {
            ContentView(store: Store(initialState: .init(title: "App Hello World",
                                                         destination: .home(.init(selectedTab: .three))), reducer: { AppFeature() }))
        }
        .modelContainer(container)
    }
}

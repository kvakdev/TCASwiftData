//
//  TCATestAppApp.swift
//  TCATestApp
//
//  Created by Andrii Kvashuk on 19/02/2024.
//

import SwiftUI
import ComposableArchitecture

@main
struct TCATestAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(store: Store(initialState: .init(), reducer: { AppFeature() }))
        }
    }
}

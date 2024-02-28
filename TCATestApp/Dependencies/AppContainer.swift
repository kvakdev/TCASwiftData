//
//  AppContainer.swift
//  TCATestApp
//
//  Created by Andrii Kvashuk on 28/02/2024.
//

import Foundation
import ComposableArchitecture
import SwiftData

extension ModelContainer: DependencyKey {
    public static var liveValue: ModelContainer {
        let schema = Schema([Book.self])
        let config = ModelConfiguration("MyBooks", schema: schema)
        do {
            print(URL.applicationSupportDirectory.path(percentEncoded: false))
            
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Could not configure the container")
        }
    }
    
    public static var previewValue: ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let schema = Schema([Book.self])
        do {
            let container = try ModelContainer(for: schema, configurations: config)
            
            Task { @MainActor in
                Book.sampleBooks.forEach { example in
                    container.mainContext.insert(example)
                }
            }
            
            return container
        } catch {
            fatalError("Could not create preview container")
        }
    }
}

extension DependencyValues {
    var appContainer: ModelContainer {
        get { self[ModelContainer.self] }
        set { self[ModelContainer.self] = newValue }
    }
}

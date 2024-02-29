//
//  ContextClient.swift
//  TCATestApp
//
//  Created by Andrii Kvashuk on 28/02/2024.
//

import Foundation
import ComposableArchitecture
import SwiftData

class ContextClient {
    @Dependency(\.appContainer) var container
    
    var context: ModelContext!
    
    init() {
        self.context = ModelContext(container)
    }
}

extension ContextClient: DependencyKey {
    static var liveValue: ContextClient = ContextClient()
}

extension DependencyValues {
    var modelContextClient: ContextClient {
        get { self[ContextClient.self] }
        set { self[ContextClient.self] = newValue }
    }
}


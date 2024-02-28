//
//  BookListContainerView.swift
//  TCATestApp
//
//  Created by Andrii Kvashuk on 28/02/2024.
//

import SwiftUI
import ComposableArchitecture
import SwiftData

enum SortOrder: String, Identifiable, CaseIterable {
    case status, title, author
    
    var id: Self {
        self
    }
}


@Reducer
struct BookListContainerFeature {
    @Dependency(\.appContainer) var container
    
    struct State: Equatable {
        var filterString: String = ""
        var books: [Book] = []
        var bookListState: BookListFeature.State?
    }
    
    enum Action: Equatable {
        case sort
        case bookList(BookListFeature.Action)
        case onAppear
        case booksFetched([Book])
        case fetchFailed
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .sort:
                return .none
            case .bookList:
                return .none
            case .booksFetched(let newBooks):
                state.bookListState =  .init(books: newBooks)
                
                return .none
            case .onAppear:
                return .run { [filterString = state.filterString] send in
                    let sortOrder = SortOrder.title
                    
                    let sortDescriptors: [SortDescriptor<Book>] = switch sortOrder {
                    case .status:
                        [SortDescriptor(\Book.status), SortDescriptor(\Book.title)]
                    case .title:
                        [SortDescriptor(\Book.title)]
                    case .author:
                        [SortDescriptor(\Book.author)]
                    }
                    let predicate = #Predicate<Book> { book in
                        book.title.localizedStandardContains(filterString)
                        || book.author.localizedStandardContains(filterString)
                        || filterString.isEmpty
                    }
                    let fetchedBooks = Query(filter: predicate, sort: sortDescriptors)
                    let context = ModelContext(container)
                    let descriptor = FetchDescriptor(predicate: predicate, sortBy: sortDescriptors)
                    
                    do {
                        let result = try context.fetch(descriptor)
                        await send(.booksFetched(result))
                    } catch {
                        await send(.fetchFailed)
                    }
                }
            case .fetchFailed:
                
                return .none
            }
        }
        .ifLet(\.bookListState, action: \.bookList) {
            BookListFeature()
        }
        ._printChanges()
        
    }
}

struct BookListContainerView: View {
    @Bindable var store: StoreOf<BookListContainerFeature>
    
    var body: some View {
        VStack {
            IfLetStore(store.scope(state: \.bookListState, action: \.bookList)) { store in
                BookListView(store: store)
            }
            Text("Text")
                .task {
                    store.send(.onAppear)
                }
        }
    }
}

#Preview {
    BookListContainerView(store: Store(initialState: .init(), reducer: {
        BookListContainerFeature()
            ._printChanges()
    }))
}

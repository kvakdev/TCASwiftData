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
        var bookListState: BookListFeature.State = .init(books: [])
    }
    
    enum Action: Equatable {
        case sort
        case bookList(BookListFeature.Action)
        case onAppear
        case booksFetched([Book])
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.bookListState, action: \.bookList) {
            BookListFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .sort:
                return .none
            case .bookList:
                return .none
            case .booksFetched(let newBooks):
                state.bookListState.books = newBooks
                
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
                    
                    await send(.booksFetched(fetchedBooks.wrappedValue))
                }
            }
        }
    }
}

struct BookListContainerView: View {
    @Bindable var store: StoreOf<BookListContainerFeature>
    
    var body: some View {
        BookListView(store: store.scope(state: \.bookListState, action: \.bookList))
            .onAppear {
                store.send(.onAppear)
            }
    }
}

#Preview {
    BookListContainerView(store: Store(initialState: .init(), reducer: {
        BookListContainerFeature()
            ._printChanges()
    }))
}

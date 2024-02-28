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
    
    @ObservableState
    struct State: Equatable {
        var filterString: String = ""
        var books: [Book] = []
        var bookListState: BookListFeature.State = .init(books: [])
        @Presents var newBook: NewBookFeature.State?
    }
    
    enum Action: Equatable {
        case sort
        case bookList(BookListFeature.Action)
        case onAppear
        case booksFetched([Book])
        case fetchFailed
        case createButtonTapped
        case newBook(PresentationAction<NewBookFeature.Action>)
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
            case .createButtonTapped:
                state.newBook = NewBookFeature.State()
                
                return .none
            case .newBook(.presented(.delegate(.didCreate))):
                
                return .send(.onAppear)
            case .newBook:
           
                return .none
            }
        }
        Scope(state: \.bookListState, action: \.bookList, child: {
            BookListFeature()
        })
        .ifLet(\.$newBook, action: \.newBook) {
            NewBookFeature()
        }
        ._printChanges()
        
    }
}

struct BookListContainerView: View {
    @Bindable var store: StoreOf<BookListContainerFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
                BookListView(store: store.scope(state: \.bookListState,
                                                action: \.bookList))
                .task {
                    store.send(.onAppear)
                }
                
        }
        .toolbar(content: {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add book") {
                    store.send(.createButtonTapped)
                }
            }
        })
        .sheet(store: store.scope(state: \.$newBook, action: \.newBook)) { store in
            NewBookView(store: store)
        }
        
    }
}

#Preview {
    BookListContainerView(store: Store(initialState: .init(), reducer: {
        BookListContainerFeature()
            ._printChanges()
    }))
}

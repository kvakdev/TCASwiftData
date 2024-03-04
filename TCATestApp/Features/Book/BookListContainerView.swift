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
    @Dependency(\.modelContextClient) var contextClient
    
    @ObservableState
    struct State: Equatable {
        var filterString: String = ""
        var books: [Book] = []
        var bookListState: BookListFeature.State = .init(books: [])
        @Presents var newBook: NewBookFeature.State?
        
        var path = StackState<BookListContainerFeature.Path.State>()
    }
    
    enum Action: Equatable {
        case sort
        case bookList(BookListFeature.Action)
        case onAppear
        case booksFetched([Book])
        case fetchFailed
        case createButtonTapped
        case newBook(PresentationAction<NewBookFeature.Action>)
        case path(StackAction<Path.State, Path.Action>)
    }
    
    @Reducer
    struct Path {
        @ObservableState
        enum State: Equatable {
            case editBook(EditBookFeature.State)
        }
        
        enum Action: Equatable {
            case editBook(EditBookFeature.Action)
        }
        
        var body: some ReducerOf<Self> {
            Reduce { state, action in
                return .none
            }
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .sort:
                return .none
            case .bookList(.delegate(.onDelete(let books))):
                return .run { send in
                    let context = self.contextClient.context!
                    for book in books {
                        context.delete(book)
                    }
                    try? context.save()
                }
            case .bookList(.delegate(.onBookTap(let book))):
                state.path.append(.editBook(EditBookFeature.State(book: book)))
                
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
                 
                    let context = contextClient.context!
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
            case .path:
                return .none
            }
        }
        Scope(state: \.bookListState, action: \.bookList, child: {
            BookListFeature()
        })
        .ifLet(\.$newBook, action: \.newBook) {
            NewBookFeature()
        }
        .forEach(\.path, action: \.path) {
            Path()
        }
        ._printChanges()
        
    }
}

struct BookListContainerView: View {
    @Bindable var store: StoreOf<BookListContainerFeature>
    
    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
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
        } destination: { store in
            SwitchStore(store) { initialState in
                switch initialState {
                case .editBook(let editState):
                    EditBookView(store: Store(initialState: editState, reducer: {
                        EditBookFeature()
                    }))
                }
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

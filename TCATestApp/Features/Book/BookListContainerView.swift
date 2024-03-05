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
    @Dependency(\.modelContextClient) var contextClient
    
    @ObservableState
    struct State: Equatable {
        var filterString: String = ""
        var books: [Book] = []
        var bookListState: BookListFeature.State = .init(books: [])
        @Presents var newBook: NewBookFeature.State?
        @Presents var deleteAlert: AlertState<Action.DeleteAction>?
        
        var path = StackState<Path.State>()
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
        case deleteAction(PresentationAction<DeleteAction>)
        
        enum DeleteAction: Equatable {
            case confirmDeletion([Book])
        }
    }
    
    @Reducer
    struct Path {
        @ObservableState
        enum State: Equatable, Hashable {
            case editBook(EditBookFeature.State)
        }
        
        enum Action: Equatable {
            case editBook(EditBookFeature.Action)
        }
        
        var body: some ReducerOf<Self> {
            Scope(state: /State.editBook, action: /Action.editBook) {
                EditBookFeature()
            }
        }
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.bookListState, action: \.bookList, child: {
            BookListFeature()
        })
        
        Reduce { state, action in
            switch action {
            case .sort:
                return .none
            case .bookList(.delegate(.onDelete(let books))):
                state.deleteAlert = AlertState(
                    title: { .init("DELETE THE BOOK") },
                    actions: {
                    ButtonState(role: .destructive, action: .confirmDeletion(books), label: { .init("Confirm")})
                })
                
                return .none

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
            case .path(.element(id: _, action: .editBook(.delegate(.completed)))):
                state.path.removeLast()
                
                return .none
            case .path:
                return .none
                
            case let .deleteAction(.presented(.confirmDeletion(books))):
                return .run { send in
                    let context = self.contextClient.context!
                    for book in books {
                        context.delete(book)
                    }
                    try? context.save()
                    await send(.bookList(.deleteConfirmed(books)))
                }
                
            case .deleteAction(.dismiss):
                state.deleteAlert = nil
                
                return .none
            }
        }
        .forEach(\.path, action: /Action.path) {
            Path()
        }
        .ifLet(\.$newBook, action: \.newBook) {
            NewBookFeature()
        }
        .ifLet(\.$deleteAlert, action: \.deleteAction)
        ._printChanges()
        
    }
}

struct BookListContainerView: View {
    let store: StoreOf<BookListContainerFeature>
    
    var body: some View {
        NavigationStackStore(self.store.scope(state: \.path, action: \.path)) {
            WithViewStore(store, observe: { $0 }) { viewStore in
                    BookListView(store: store.scope(state: \.bookListState,
                                                    action: \.bookList))
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
            .alert(store: store.scope(state: \.$deleteAlert, action: \.deleteAction))
            
        } destination: { store in
            SwitchStore(store) { initialState in
                switch initialState {
                case .editBook:
                    CaseLet(/BookListContainerFeature.Path.State.editBook,
                            action: BookListContainerFeature.Path.Action.editBook) { store in
                        EditBookView(store: store)
                    }
                }
            }
            
        }
        .onAppear(perform: {
            store.send(.onAppear)
        })
    }
}

#Preview {
    let store = Store<BookListContainerFeature.State, BookListContainerFeature.Action>(initialState: BookListContainerFeature.State.init(), reducer: {
        BookListContainerFeature()
            ._printChanges()
    })
    
    return BookListContainerView(store: store)
        .modelContainer(ModelContainer.previewValue)
}

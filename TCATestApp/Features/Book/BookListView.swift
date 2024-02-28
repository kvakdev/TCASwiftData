//
//  BookListView.swift
//  TCATestApp
//
//  Created by Andrii Kvashuk on 27/02/2024.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct BookListFeature {
    struct State: Equatable {
        var books: [Book]
    }
    
    enum Action: Equatable {
        case delete(IndexSet)
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case onDelete(IndexSet)
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .delegate:
                return .none
            case .delete(let indexSet):
                return .send(.delegate(.onDelete(indexSet)))
            }
        }
    }
}

struct BookListView: View {
    let store: StoreOf<BookListFeature>
    @State var createNewBook = false
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Group {
                if viewStore.books.isEmpty {
                    ContentUnavailableView("Enter your first book.", systemImage: "book.fill")
                } else {
                    List {
                        ForEach(viewStore.books) { book in
                            NavigationLink {
                                Text(book.title)
                            } label: {
                                HStack(spacing: 10) {
                                    book.icon
                                    VStack(alignment: .leading) {
                                        Text(book.title).font(.title2)
                                        Text(book.author).foregroundStyle(.secondary)
                                        if let rating = book.rating {
                                            HStack {
                                                ForEach(1..<rating, id: \.self) { _ in
                                                    Image(systemName: "star.fill")
                                                        .imageScale(.small)
                                                        .foregroundStyle(.yellow)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                        }
                        .onDelete { indexSet in
                            store.send(.delete(indexSet))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add book") {
                        createNewBook = true
                    }
                }
            })
            .sheet(isPresented: $createNewBook) {
                NewBookView()
                    .presentationDetents([.medium])
            }
        }
    }
}

#Preview("Some books") {
    let preview = Preview(Book.self)
    preview.addExamples(Book.sampleBooks)
    
    return NavigationStack {
        BookListView(store: Store(initialState: BookListFeature.State(books: Book.sampleBooks), reducer: { BookListFeature()
        }))
    }
}

#Preview("No books") {
    return NavigationStack {
        BookListView(store: Store(initialState: BookListFeature.State(books: []), reducer: { BookListFeature()
        }))
    }
}

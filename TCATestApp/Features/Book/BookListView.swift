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
        case delete(Book)
        case delegate(Delegate)
        case tap(Tap)
        case deleteConfirmed([Book])
        
        enum Delegate: Equatable {
            case onDelete([Book])
            case onBookTap(Book)
        }
        
        enum Tap: Equatable {
            case book(Book)
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .delegate:
                return .none
            case .delete(let book):
      
                return .send(.delegate(.onDelete([book])))
                
            case .deleteConfirmed(let books):
                var indexSet = IndexSet()
                
                for book in books {
                    if let index = state.books.firstIndex(of: book) {
                        indexSet.insert(index)
                    }
                }
                state.books.remove(atOffsets: indexSet)
                
                return .none
                
            case .tap(let tap):
                switch tap {
                case .book(let book):
                    return .send(.delegate(.onBookTap(book)))
                }
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
                            HStack {
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
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    store.send(.tap(.book(book)))
                                }
                                
                                Button {
                                    store.send(.delete(book))
                                } label: {
                                    Image(systemName: "trash.fill")
                                        .imageScale(.small)
                                        .foregroundStyle(.black)
                                        .frame(width: 60)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
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

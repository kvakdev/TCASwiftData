//
//  EditBookView.swift
//  TCATestApp
//
//  Created by Andrii Kvashuk on 29/02/2024.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct EditBookFeature {
    @Dependency(\.dismiss) private var dismiss
    @Dependency(\.modelContextClient) private var contextClient
    
    struct State: Equatable, Hashable {
        let book: Book
        @BindingState var status = Status.onShelf
        @BindingState var rating: Int?
        @BindingState var title = ""
        @BindingState var author = ""
        @BindingState var synopsis = ""
        @BindingState var dateAdded = Date.distantPast
        @BindingState var dateStarted = Date.distantPast
        @BindingState var dateCompleted = Date.distantPast
        @BindingState var firstView = true
        @BindingState var recommendedBy = ""
        
        var changed: Bool {
            status != Status(rawValue: book.status)!
            || rating != book.rating
            || title != book.title
            || author != book.author
            || synopsis != book.synopsis
            || dateAdded != book.dateAdded
            || dateStarted != book.dateStarted
            || dateCompleted != book.dateCompleted
            || recommendedBy != book.recommendedBy
        }
        
        init(book: Book) {
            self.book = book
            
            status = Status(rawValue: book.status)!
            rating = book.rating
            title = book.title
            author = book.author
            synopsis = book.synopsis
            dateAdded = book.dateAdded
            dateStarted = book.dateStarted
            dateCompleted = book.dateCompleted
            recommendedBy = book.recommendedBy
        }
    }
    
    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case updateButtonTapped
        case setNewValues
        case dismiss
        case delegate(Delegate)
        
        enum Delegate {
            case completed
        }
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
//            .onChange(of: viewStore.status) { oldValue, newValue in
//                    if !firstView {
//                        if newValue == .onShelf {
//                            dateStarted = Date.distantPast
//                            dateCompleted = Date.distantPast
//                        } else if newValue == .inProgress && oldValue == .completed {
//                            // from completed to inProgress
//                            dateCompleted = Date.distantPast
//                        } else if newValue == .inProgress && oldValue == .onShelf {
//                            // Book has been started
//                            dateStarted = Date.now
//                        } else if newValue == .completed && oldValue == .onShelf {
//                            // Forgot to start book
//                            dateCompleted = Date.now
//                            dateStarted = dateAdded
//                        } else {
//                            // completed
//                            dateCompleted = Date.now
//                        }
//                        firstView = false
//                    }
//            }
        Reduce { state, action in
            switch action {
            case .updateButtonTapped:
                return .run { send in
                    await send(.setNewValues)
                    await send(.delegate(.completed))
                }
                
            case .binding:
                return .none
                
            case .setNewValues:
                state.book.status = state.status.rawValue
                state.book.rating = state.rating
                state.book.title = state.title
                state.book.author = state.author
                state.book.synopsis = state.synopsis
                state.book.dateAdded = state.dateAdded
                state.book.dateStarted = state.dateStarted
                state.book.dateCompleted = state.dateCompleted
                state.book.recommendedBy = state.recommendedBy
                
                try! contextClient.context.save()
                
                return .none
            case .dismiss:
                return .run { send in
                    await dismiss()
                }
            case .delegate(_):
                return .none
            }
        }
        ._printChanges()
    }
}

struct EditBookView: View {
    @Bindable var store: StoreOf<EditBookFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            HStack {
                Text("Status")
                Picker("Status", selection: viewStore.$status) {
                    ForEach(Status.allCases) { status in
                        Text(status.descr).tag(status)
                    }
                }
                .buttonStyle(.bordered)
            }
            VStack(alignment: .leading) {
                GroupBox {
                    LabeledContent {
                        DatePicker("", selection: viewStore.$dateAdded, displayedComponents: .date)
                    } label: {
                        Text("Date Added")
                    }
                    if viewStore.status == .inProgress || viewStore.status == .completed {
                        LabeledContent {
                            DatePicker("", selection: viewStore.$dateStarted, in: viewStore.dateAdded..., displayedComponents: .date)
                        } label: {
                            Text("Date Started")
                        }
                    }
                    if viewStore.status == .completed {
                        LabeledContent {
                            DatePicker("", selection: viewStore.$dateCompleted, in: viewStore.dateStarted..., displayedComponents: .date)
                        } label: {
                            Text("Date Completed")
                        }
                    }
                }
                .foregroundStyle(.secondary)
                
                Divider()
                LabeledContent {
                    RatingsView(maxRating: 5, currentRating: viewStore.$rating, width: 30)
                } label: {
                    Text("Rating")
                }
                LabeledContent {
                    TextField("", text: viewStore.$title)
                } label: {
                    Text("Title").foregroundStyle(.secondary)
                }
                LabeledContent {
                    TextField("", text: viewStore.$author)
                } label: {
                    Text("Author").foregroundStyle(.secondary)
                }
                LabeledContent {
                    TextField("", text: viewStore.$recommendedBy)
                } label: {
                    Text("Recommended by").foregroundStyle(.secondary)
                }
                Divider()
                Text("Synopsis").foregroundStyle(.secondary)
                TextEditor(text: viewStore.$synopsis)
                    .padding(5)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(uiColor: .tertiarySystemFill), lineWidth: 2))
    //            NavigationLink {
    //                QuotesListView(book: book)
    //            } label: {
    //                let count = book.quotes?.count ?? 0
    //                Label("^[\(count) Quotes](inflect: true)", systemImage: "quote.opening")
    //            }
    //            .buttonStyle(.bordered)
    //            .frame(maxWidth: .infinity, alignment: .trailing)
    //            .padding(.horizontal)

            }
            .padding()
            .textFieldStyle(.roundedBorder)
            .navigationTitle(viewStore.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewStore.changed {
                    Button("Update") {
                        store.send(.updateButtonTapped)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

#Preview {
    let preview = Preview(Book.self)
   return  NavigationStack {
       EditBookView(store: Store(initialState: .init(book: Book.sampleBooks[4]), reducer: {
           EditBookFeature()
       }))
           .modelContainer(preview.container)
    }
}

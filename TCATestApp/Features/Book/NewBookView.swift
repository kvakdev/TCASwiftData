////
////  NewBookView.swift
////  TCATestApp
////
////  Created by Andrii Kvashuk on 28/02/2024.
////
//
//import SwiftUI
//import SwiftData
//import ComposableArchitecture
//
//@Reducer
//struct NewBookFeature {
//    @Dependency(\.appContainer) var container
//    @Dependency(\.dismiss) var dismiss
//    
//    @ObservableState
//    struct State: Equatable {
//        @BindingState var title = ""
//        @BindingState var author = ""
//    }
//    
//    enum Action: Equatable, BindableAction {
//        case binding(BindingAction<State>)
//        case createButtonTapped
//        case cancelButtonTapped
//    }
//    
//    var body: some ReducerOf<Self> {
//        BindingReducer()
//        
//        Reduce { state, action in
//            switch action {
//            case .binding:
//                return .none
//            case .cancelButtonTapped:
//                return .run {
//                    await dismiss()
//                }
//            case .createButtonTapped:
//                let newBook = Book(title: state.title, author: state.author)
//                
//                return .run { send in
//                    let context = ModelContext(container)
//                    context.insert(newBook)
//                }
//            }
//        }
//    }
//}
//
//struct NewBookView: View {
//    @Bindable var store: StoreOf<NewBookFeature>
//    
//    var body: some View {
//        WithViewStore(self.store, observe: { $0 }) { viewStore in
//            NavigationStack {
//                Form {
//                    TextField("Book Title", text: viewStore.$title)
//                    TextField("Author", text: viewStore.$author)
//                    Button("Create") {
//                        store.send(.createButtonTapped)
//                    }
//                    .frame(maxWidth: .infinity, alignment: .trailing)
//                    .buttonStyle(.borderedProminent)
//                    .padding(.vertical)
//                    .disabled(viewStore.title.isEmpty || viewStore.author.isEmpty)
//                    .navigationTitle("New Book")
//                    .navigationBarTitleDisplayMode(.inline)
//                    .toolbar {
//                        ToolbarItem(placement: .topBarLeading) {
//                            Button("Cancel") {
//                                store.send(.cancelButtonTapped)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
//
//#Preview {
//    NewBookView(store: Store(initialState: .init(), reducer: { NewBookFeature()._printChanges() }))
//}
//

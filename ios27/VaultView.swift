//
//  VaultView.swift
//  ios27
//
//  Created by Justin Storm on 7/5/26.
//

import SwiftUI
import SwiftData
import LocalAuthentication

struct VaultView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.isSearching) private var isSearching

    @Query(sort: \ListClass.createdAt, order: .reverse)
    private var lists: [ListClass]

    var lockedLists: [ListClass] {
        lists.filter { $0.locked == true }
    }

    var filteredLists: [ListClass] {
        let base = lockedLists
        guard !searchText.isEmpty else { return base }
        return base.filter { ($0.title ?? "").localizedCaseInsensitiveContains(searchText) }
    }

    var pinnedLists: [ListClass] {
        filteredLists.filter { $0.pinned == true }
    }

    var unpinnedLists: [ListClass] {
        filteredLists.filter { $0.pinned != true }
    }

    var gridColumns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    @State private var loggedIn = false
    @State private var text: String = ""
    @State private var biometricError: String?

    @State private var addListSheetShowing = false

    @State private var listToDelete: ListClass?
    @State private var listToEdit: ListClass?

    @State private var searchText = ""

    @Namespace private var namespace

    var body: some View {
        NavigationStack {
            Group {
                if !loggedIn {
                    ContentUnavailableView {
                        Label("Vault is Locked", systemImage: "lock.shield.fill")
                    } description: {
                        if let biometricError {
                            Text(biometricError)
                                .foregroundColor(.red)
                        } else {
                            Text("Use Face ID or your device passcode to access your vault.")
                        }
                    } actions: {
                        Button(action: {
                            authenticateWithDeviceCredentials()
                        }) {
                            Label("Unlock Vault", systemImage: "lock.open.fill")
                                .font(.headline)
                                .padding(.horizontal, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                } else if (lockedLists.isEmpty) {
                    ContentUnavailableView {
                        Label("No Locked lists", systemImage: "lock.shield.fill")
                    } description: {
                        Text("Tap + to create your first list.")
                    } actions: {
                        Button(action: {
                            addListSheetShowing = true
                        }) {
                            Text("Add List")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if (filteredLists.isEmpty) {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    VaultListsGrid(
                        pinnedLists: pinnedLists,
                        unpinnedLists: unpinnedLists,
                        filteredLists: filteredLists,
                        gridColumns: gridColumns,
                        listToDelete: $listToDelete,
                        listToEdit: $listToEdit,
                        namespace: namespace
                    )
                }
            }
            .navigationTitle(loggedIn ? "🔒 Vault" : "")
            .sheet(isPresented: $addListSheetShowing) {
                AddListView(listLocked: true)
                    .navigationTransition(.zoom(sourceID: "addListButton", in: namespace))
            }
            .sheet(item: $listToEdit) { list in
                EditListView(list: list)
                    .navigationTransition(.zoom(sourceID: "editListBlock", in: namespace))
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                if loggedIn {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            addListSheetShowing = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .matchedTransitionSource(id: "addListButton", in: namespace)
                    }
                }
            }
            .alert("Delete List", item: $listToDelete) { list in
                Button(role: .cancel) {
                    listToDelete = nil
                } label: {
                    Text("Cancel")
                }
                Button(role: .destructive) {
                    deleteList()
                } label: {
                    Text("Delete")
                }
            } message: { list in
                Text("Are you sure you want to delete \(list.title ?? "Untitled")?")
            }
            .searchable(text: $searchText)
            .onAppear {
                if !loggedIn {
                    authenticateWithDeviceCredentials()
                }
            }
            .navigationDestination(for: ListClass.self) { list in
                ListView(list: list)
            }
        }
    }

    private func deleteList() {
        guard let list = listToDelete else { return }
        modelContext.delete(list)
        try? modelContext.save()
        listToDelete = nil
    }

    func authenticateWithDeviceCredentials() {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            biometricError = "Authentication methods unavailable"
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Log in to your Vault") { success, authError in
            DispatchQueue.main.async {
                if success {
                    withAnimation(.easeInOut) {
                        loggedIn = true
                    }
                } else {
                    biometricError = authError?.localizedDescription
                }
            }
        }
    }
}

private struct VaultListsGrid: View {
    @Environment(\.isSearching) private var isSearching

    let pinnedLists: [ListClass]
    let unpinnedLists: [ListClass]
    let filteredLists: [ListClass]
    let gridColumns: [GridItem]
    @Binding var listToDelete: ListClass?
    @Binding var listToEdit: ListClass?
    let namespace: Namespace.ID

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(pinnedLists) { list in
                        ListBlock(list: list, listToDelete: $listToDelete, listToEdit: $listToEdit)
                            .transition(.scale.combined(with: .opacity))
                            .matchedTransitionSource(id: "editListBlock", in: namespace)
                    }
                    ForEach(unpinnedLists) { list in
                        ListBlock(list: list, listToDelete: $listToDelete, listToEdit: $listToEdit)
                            .transition(.scale.combined(with: .opacity))
                            .matchedTransitionSource(id: "editListBlock", in: namespace)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, isSearching ? 16 : 0)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: pinnedLists.map(\.id))
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: unpinnedLists.map(\.id))
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: filteredLists.map(\.id))
            .animation(.easeInOut(duration: 0.25), value: isSearching)
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }
    }
}

//
//  ContentView.swift
//  ios27
//
//  Created by Justin Storm on 6/20/26.
//

import SwiftUI
import SwiftData
import UserNotifications

struct ListBlockContent: View {
    @Environment(\.modelContext) private var modelContext
    var list: ListClass
    @Binding var listToDelete: ListClass?
    @Binding var listToEdit: ListClass?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if list.glassEffect == true {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.clear)
                    .glassEffect(.clear.tint(color(from: list.color ?? "blue")), in: .rect(cornerRadius: 20))
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(color(from: list.color ?? "blue").gradient)
            }

            Image(systemName: list.icon ?? "checklist")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.15))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: list.textTrailing == true ? .topLeading : .topTrailing)
                .padding(12)

            if list.locked == true {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: list.textTrailing == true ? .bottomLeading : .bottomTrailing)
                    .padding()
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if list.textTrailing == true {
                        if list.pinned == true {
                            Image(systemName: "pin.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .rotationEffect(.degrees(45))
                        }

                        Spacer()

                        Image(systemName: list.icon ?? "checklist")
                            .font(.title2)
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: list.icon ?? "checklist")
                            .font(.title2)
                            .foregroundStyle(.white)

                        Spacer()

                        if list.pinned == true {
                            Image(systemName: "pin.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .rotationEffect(.degrees(45))
                        }
                    }
                }
                Spacer()
                Text(list.title ?? "Untitled")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: list.textTrailing == true ? .trailing : .leading)
                    .lineLimit(1)
                Text("^[\(list.tasksArray.count) task](inflect: true)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(maxWidth: .infinity, alignment: list.textTrailing == true ? .trailing : .leading)
            }
            .padding()
        }
        .frame(height: 150)
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .contextMenu {
            ControlGroup {
                Button {
                    listToEdit = list
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        list.pinned?.toggle()
                        try? modelContext.save()
                    }
                } label: {
                    Label(list.pinned == true ? "Unpin" : "Pin", systemImage: list.pinned == true ? "pin.slash.fill" : "pin.fill")
                }
                Button(role: .destructive) {
                    listToDelete = list
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            Button {
                list.locked?.toggle()
                try? modelContext.save()
            } label: {
                Label(list.locked == true ? "Unlock" : "Lock", systemImage: list.locked == true ? "lock.open.fill" : "lock.fill")
            }
        }
    }

    private func color(from name: String) -> Color {
        switch name {
        case "red":     return .red
        case "orange":  return .orange
        case "yellow":  return .yellow
        case "green":   return .green
        case "blue":    return .blue
        case "indigo":  return .indigo
        case "pink":    return .pink
        case "brown":   return .brown
        case "mint":    return .mint
        case "teal":    return .teal
        default:        return .secondary
        }
    }

    private func duplicateList(list: ListClass) {
        let newList = ListClass.create(
            in: modelContext,
            icon: list.icon ?? "checklist",
            title: "\(list.title ?? "Untitled") (copy)",
            color: list.color ?? "blue",
            order: list.order ?? ListSortOrder.newest.rawValue,
            pinned: list.pinned ?? false,
            locked: list.locked ?? false,
            textTrailing: list.textTrailing ?? false,
            glassEffect: list.glassEffect ?? false,
            backgroundType: list.backgroundType,
            color1: list.color1,
            color2: list.color2,
            gradientAngle: list.gradientAngle,
            imageData: list.imageData
        )

        for task in list.tasksArray {
            TaskClass.create(
                in: modelContext,
                title: task.title ?? "",
                note: task.note,
                url: task.url,
                date: task.date,
                repeatType: task.repeatType ?? RepeatType.none.rawValue,
                flagged: task.flagged == true,
                priority: task.priority ?? Priority.none.rawValue,
                list: newList
            )
        }

        try? modelContext.save()
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \ListClass.createdAt, order: .reverse) private var lists: [ListClass]

    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var preferredColumn: NavigationSplitViewColumn = .sidebar
    @State private var selectedItem: SidebarItem?

    enum SidebarItem: Hashable {
        case today
        case list(ListClass)
    }

    @State private var addListSheetOpen = false
    @State private var searchText = ""
    @State private var listToDelete: ListClass?
    @State private var listToEdit: ListClass?
    @State private var showDeleteAlert = false
    @State private var vaultSheetOpen = false
    @Namespace private var namespace

    @State private var gridWidth: CGFloat = 0

    private let minBlockWidth: CGFloat = 150
    private let gridSpacing: CGFloat = 12

    var gridColumns: [GridItem] {
        // 2 columns if two blocks fit at the minimum width, otherwise 1
        let needed = minBlockWidth * 2 + gridSpacing
        let count = gridWidth >= needed ? 2 : 1
        return Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: count)
    }

    var unlockedLists: [ListClass] {
        lists.filter { $0.locked != true }
    }

    var filteredLists: [ListClass] {
        guard !searchText.isEmpty else { return unlockedLists }
        return unlockedLists.filter { ($0.title ?? "").localizedCaseInsensitiveContains(searchText) }
    }

    /// Pinned first, then the rest (each group keeps the @Query order)
    var displayLists: [ListClass] {
        filteredLists.filter { $0.pinned == true } + filteredLists.filter { $0.pinned != true }
    }

    private var todayTasksCount: Int {
        unlockedLists
            .flatMap { ($0.tasks ?? []) }
            .filter { task in
                guard let date = task.date else { return true }
                return date <= Date()
            }
            .count
    }

    private var todayCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.blue.gradient)
                    .frame(width: 48, height: 48)

                Image(systemName: "\(Calendar.current.component(.day, from: Date())).calendar")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Today")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("^[\(todayTasksCount) Task](inflect: true)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: .rect(cornerRadius: 20))
        .overlay {
            if isSelected(.today) {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.accentColor, lineWidth: 3)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 20))
    }

    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            preferredCompactColumn: $preferredColumn
        ) {
            Group {
                if !searchText.isEmpty && filteredLists.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else if unlockedLists.isEmpty {
                    ContentUnavailableView {
                        Label("No Lists", systemImage: "checklist")
                    } description: {
                        Text("You have no lists added.")
                    } actions: {
                        Button {
                            addListSheetOpen = true
                        } label: {
                            Text("Add List")
                        }.buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            if searchText.isEmpty {
                                Button {
                                    select(.today)
                                } label: {
                                    todayCard
                                }
                                .buttonStyle(.plain)
                            }

                            LazyVGrid(columns: gridColumns, spacing: 12) {
                                ForEach(displayLists) { list in
                                    Button {
                                        select(.list(list))
                                    } label: {
                                        ListBlockContent(
                                            list: list,
                                            listToDelete: $listToDelete,
                                            listToEdit: $listToEdit
                                        )
                                        .overlay {
                                            if isSelected(.list(list)) {
                                                RoundedRectangle(cornerRadius: 20)
                                                    .strokeBorder(Color.accentColor, lineWidth: 3)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: displayLists.map(\.persistentModelID))
                        }
                        .onGeometryChange(for: CGFloat.self) { proxy in
                            proxy.size.width
                        } action: { newWidth in
                            gridWidth = newWidth
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle("Lists")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        vaultSheetOpen = true
                    } label: {
                        Image(systemName: "lock.fill")
                    }
                    .matchedTransitionSource(id: "vaultButton", in: namespace)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addListSheetOpen = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .matchedTransitionSource(id: "addListButton", in: namespace)
                }
            }
            .sheet(isPresented: $addListSheetOpen) {
                AddListView(listLocked: false)
                    .navigationTransition(.zoom(sourceID: "addListButton", in: namespace))
            }
            .sheet(isPresented: $vaultSheetOpen) {
                VaultView()
                    .navigationTransition(.zoom(sourceID: "vaultButton", in: namespace))
            }
            .sheet(item: $listToEdit) { list in
                EditListView(list: list)
            }
            .onChange(of: listToDelete) { _, newValue in
                showDeleteAlert = newValue != nil
            }
            .alert("Delete List", isPresented: $showDeleteAlert, presenting: listToDelete) { _ in
                Button("Cancel", role: .cancel) {
                    listToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    deleteList()
                }
            } message: { list in
                Text("Are you sure you want to delete \(list.title ?? "Untitled")?")
            }
            .searchable(text: $searchText)
            .onReceive(NotificationCenter.default.publisher(for: .quickAction)) { notification in
                guard let type = notification.object as? String else { return }

                switch type {
                case "com.stormxr.newtest.addList":
                    addListSheetOpen = true
                case "com.stormxr.newtest.vault":
                    vaultSheetOpen = true
                default:
                    break
                }
            }
        } detail: {
            switch selectedItem {
            case .today:
                TodayView()
            case .list(let list):
                ListView(list: list)
            case nil:
                ContentUnavailableView("No Selection", systemImage: "checklist")
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            if horizontalSizeClass == .regular {
                selectedItem = .today
            }
        }
    }

    // MARK: - Helpers

    private func select(_ item: SidebarItem) {
        selectedItem = item
        preferredColumn = .detail   // pushes to detail on iPhone
    }

    /// Only show the selection ring on iPad, where the sidebar and detail are visible together
    private func isSelected(_ item: SidebarItem) -> Bool {
        horizontalSizeClass == .regular && selectedItem == item
    }

    private func deleteList() {
        guard let list = listToDelete else { return }

        for task in list.tasksArray {
            NotificationManager.cancelAll(identifier: task.notificationId)
        }

        if selectedItem == .list(list) {
            selectedItem = horizontalSizeClass == .regular ? .today : nil
        }

        modelContext.delete(list)
        try? modelContext.save()
        listToDelete = nil
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [
                ListClass.self,
                TaskClass.self
            ],
            inMemory: true
        )
}

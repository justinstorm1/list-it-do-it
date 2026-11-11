//
//  TodayView.swift
//  ios27
//
//  Created by Justin Storm on 8/24/26.
//

import SwiftUI
import SwiftData
import WidgetKit

enum TodayTaskFilter: Hashable {
    case all
    case overdue
    case undated
}

enum TodayTaskSort: Hashable {
    case dateAscending
    case dateDescending
    case nameAscending
    case nameDescending
}

struct TodayView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let today = Date().formatted(date: .long, time: .omitted)
    
    @Query private var lists: [ListClass]
    
    @State private var taskToEdit: TaskClass?
    
    @State private var searchText: String = ""
    
    @State private var taskFilter: TodayTaskFilter = .all
    @State private var taskSort: TodayTaskSort = .dateAscending
    
    var todayTasks: [TaskClass] {
        lists
            .filter { $0.locked != true }
            .flatMap { list in
                (list.tasks ?? []).filter { task in
                    guard let date = task.date else {
                        return true
                    }

                    return date <= Date()
                }
        }
    }
    
    var filteredTasks: [TaskClass] {
        let base: [TaskClass]

        switch taskFilter {
        case .all:
            base = todayTasks

        case .overdue:
            base = todayTasks.filter { task in
                guard let date = task.date else {
                    return false
                }

                return date < Date()
            }

        case .undated:
            base = todayTasks.filter { task in
                task.date == nil
            }
        }

        let searched: [TaskClass]

        if searchText.isEmpty {
            searched = base
        } else {
            searched = base.filter {
                ($0.title ?? "")
                    .localizedCaseInsensitiveContains(searchText)
            }
        }

        switch taskSort {
        case .dateAscending:
            return searched.sorted { first, second in
                switch (first.date, second.date) {
                case let (date1?, date2?):
                    return date1 < date2

                case (nil, _?):
                    return false

                case (_?, nil):
                    return true

                case (nil, nil):
                    return (first.title ?? "")
                        .localizedCaseInsensitiveCompare(second.title ?? "") == .orderedAscending
                }
            }
        case .dateDescending:
            return searched.sorted { first, second in
                switch (first.date, second.date) {
                case let (date1?, date2?):
                    return date1 > date2

                case (nil, _?):
                    return false

                case (_?, nil):
                    return true

                case (nil, nil):
                    return (first.title ?? "")
                        .localizedCaseInsensitiveCompare(second.title ?? "") == .orderedAscending
                }
            }
        case .nameAscending:
            return searched.sorted {
                ($0.title ?? "")
                    .localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending
            }
        case .nameDescending:
            return searched.sorted {
                ($0.title ?? "")
                    .localizedCaseInsensitiveCompare($1.title ?? "") == .orderedDescending
            }
        }
    }
    
    private func deleteTask(task: TaskClass) {
        NotificationManager.cancelAll(identifier: task.notificationId)
        modelContext.delete(task)
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func transferTask(_ task: TaskClass, to destination: ListClass) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            task.list = destination
        }
        try? modelContext.save()
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if filteredTasks.isEmpty && searchText.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing for Today", systemImage: "checkmark.circle")
                    } description: {
                        Text("You have no tasks due today or overdue.")
                    }
                } else if (filteredTasks.isEmpty && !searchText.isEmpty) {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        ForEach(lists) { list in
                            let listTasks = filteredTasks.filter { task in
                                task.list?.id == list.id
                            }
                            
                            if !listTasks.isEmpty {
                                Section(list.title ?? "Untitled List") {
                                    ForEach(listTasks) { task in
                                        let transferableLists = lists.filter {
                                            $0.id != task.list?.id
                                        }
                                        TaskRowView(
                                            task: task,
                                            isListView: false,
                                            tint: listColor(from: list.color ?? "blue"),
                                            useGlass: false,
                                            transferableLists: transferableLists,
                                            onEdit: { taskToEdit = task },
                                            onDelete: { deleteTask(task: task) },
                                            onTransfer: { destination in transferTask(task, to: destination) }
                                        )
                                        .listRowInsets(EdgeInsets())
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                    }
                                }
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: filteredTasks.map(\.id))
                            }
                        }
                    }
                    .listStyle(.plain)
                    .padding(.horizontal, 1)
                    .listStyle(.automatic)
                }
            }
            .navigationTitle("\(today)")
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort By", selection: $taskSort) {
                            Label("Earliest First", systemImage: "arrow.up")
                                .tag(TodayTaskSort.dateAscending)
                            Label("Latest First", systemImage: "arrow.down")
                                .tag(TodayTaskSort.dateDescending)
                            Label("A-Z", systemImage: "arrow.up")
                                .tag(TodayTaskSort.nameAscending)

                            Label("Z-A", systemImage: "arrow.down")
                                .tag(TodayTaskSort.nameDescending)
                        }
                        Picker(selection: $taskFilter) {
                            Label("All Tasks", systemImage: "checklist")
                                .tag(TodayTaskFilter.all)

                            Label("Overdue", systemImage: "exclamationmark.circle")
                                .tag(TodayTaskFilter.overdue)

                            Label("No Date", systemImage: "calendar.badge.exclamationmark")
                                .tag(TodayTaskFilter.undated)
                        } label: {
                            Label("Filter", systemImage: "line.3.horizontal.decrease")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                }
            }
            .sheet(item: $taskToEdit) { task in
                if let list = task.list {
                    EditTaskView(list: list, task: task)
                }
            }
        }
    }
}

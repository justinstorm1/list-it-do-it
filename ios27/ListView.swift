//
//  ListView.swift
//  ios27
//
//  Created by Justin Storm on 6/24/26.
//

import SwiftUI
import SwiftData
import WidgetKit

struct ListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \ListClass.createdAt, order: .reverse)
    private var lists: [ListClass]

    var list: ListClass

    var transferableLists: [ListClass] {
        lists.filter { $0 !== list }
    }

    private var canEdit: Bool { true }

    @State private var addTaskSheetShowing = false
    @State private var taskToEdit: TaskClass?
    @State private var popoverTask: TaskClass?
    @State private var sortOrder: ListSortOrder

    init(list: ListClass) {
        self.list = list
        _sortOrder = State(initialValue: ListSortOrder(rawValue: list.order ?? "Newest") ?? .newest)
    }

    var sortedTasks: [TaskClass] {
        let tasks = list.tasksArray
        switch sortOrder {
        case .newest:
            return tasks.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        case .oldest:
            return tasks.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
        case .aToZ:
            return tasks.sorted { ($0.title ?? "") < ($1.title ?? "") }
        case .zToA:
            return tasks.sorted { ($0.title ?? "") > ($1.title ?? "") }
        case .date:
            return tasks.sorted { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) }
        case .priority:
            return tasks.sorted { priorityRank($0.priority) > priorityRank($1.priority) }
        }
    }

    var filteredTasks: [TaskClass] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return sortedTasks
        }
        return sortedTasks.filter { task in
            let titleMatch = task.title?.localizedCaseInsensitiveContains(searchText) ?? false
            let noteMatch = task.note?.localizedCaseInsensitiveContains(searchText) ?? false
            return titleMatch || noteMatch
        }
    }

    @State private var deleteListAlertShowing = false
    @State private var searchText = ""
    @State private var editingList = false
    @Namespace private var namespace

    var gradient: LinearGradient {
        let radians = ((list.gradientAngle ?? 180) - 90) * .pi / 180
        let x = cos(radians)
        let y = sin(radians)

        return LinearGradient(
            colors: [Color(hex: list.color1 ?? "#3478F8FF").opacity(0.75), Color(hex: list.color2 ?? "#FF2D9DFF").opacity(0.75)],
            startPoint: .init(x: 0.5 - x/2, y: 0.5 - y/2),
            endPoint: .init(x: 0.5 + x/2, y: 0.5 + y/2)
        )
    }

    @ViewBuilder
    var backgroundView: some View {
        if list.backgroundType == "gradient" {
            gradient
                .ignoresSafeArea()
        } else if list.backgroundType == "image",
                  let data = list.imageData,
                  let uiImage = UIImage(data: data) {
            GeometryReader { geo in
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea() 
            }
            .ignoresSafeArea()
        } else {
            Color(.systemBackground)
                .ignoresSafeArea()
        }
    }

    @State private var notesExpanded = false

    @ViewBuilder
    var notesCard: some View {
        if let notes = list.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundStyle(listColor(from: list.color ?? "blue"))
                    Text("Notes")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if notes.count > 120 {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                notesExpanded.toggle()
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                                .rotationEffect(.degrees(notesExpanded ? 180 : 0))
                                .foregroundStyle(listColor(from: list.color ?? "blue"))
                        }
                    }
                }

                Text(notes)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .lineLimit(notesExpanded ? nil : 3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .onTapGesture {
                guard notes.count > 120 else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    notesExpanded.toggle()
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if list.tasksArray.isEmpty && searchText.isEmpty {
                    notesCard
                        .padding(.horizontal, 16)
                    ContentUnavailableView {
                        Label("No tasks", systemImage: list.icon ?? "checklist")
                    } description: {
                        Text("Press + button to add your first task")
                    } actions: {
                        Button("Add Task") {
                            addTaskSheetShowing = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(listColor(from: list.color ?? "blue"))
                    }
                } else if (filteredTasks.isEmpty && !searchText.isEmpty) {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        ForEach(filteredTasks) { task in
                            TaskRowView(
                                task: task,
                                isListView: true,
                                tint: listColor(from: list.color ?? "blue"),
                                useGlass: list.glassEffect == true,
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
                    .padding(.horizontal, list.backgroundType != "none" || list.glassEffect == true ? 20 : 1)
                    .listStyle(.automatic)
                    .listRowSpacing(list.backgroundType != "none" ? 16 : 0)
                    .scrollContentBackground(.hidden)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: filteredTasks.map(\.id))
                }
            }
            .background(backgroundView)
            .navigationTitle(list.title ?? "Untitled")
            .navigationSubtitle("^[\(list.tasksArray.count) task](inflect: true)")
            .toolbar {
                ToolbarItem {
                    Menu {
                        Button {
                            editingList = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Picker(selection: $sortOrder) {
                            ForEach(ListSortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        } label: {
                            Label("Order", systemImage: "arrow.up.arrow.down")
                        }
                        .pickerStyle(.menu)
                        .onChange(of: sortOrder) { _, newValue in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                list.order = newValue.rawValue
                                try? modelContext.save()
                            }
                        }
                        Divider()
                        Button(role: .destructive) {
                            deleteListAlertShowing = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addTaskSheetShowing = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(listColor(from: list.color ?? "blue"))
                    .matchedTransitionSource(id: "addListButton", in: namespace)
                }
            }
            .sheet(isPresented: $addTaskSheetShowing) {
                AddTaskView(list: list)
                    .navigationTransition(.zoom(sourceID: "addListButton", in: namespace))
            }
            .sheet(item: $taskToEdit) { task in
                EditTaskView(list: list, task: task)
//                    .navigationTransition(.zoom(sourceID: task.persistentModelID, in: namespace))
            }
            .sheet(isPresented: $editingList) {
                EditListView(list: list)
            }
            .alert("Delete List", isPresented: $deleteListAlertShowing) {
                Button(role: .cancel) {
                    //
                } label: {
                    Text("Cancel")
                }
                Button(role: .destructive) {
                    deleteList()
                } label: {
                    Text("Delete")
                }
            } message: {
                Text("Are you sure you want tom delete this list?")
            }
            .onAppear {
                sortOrder = ListSortOrder(rawValue: list.order ?? "Newest") ?? .newest
            }
            .searchable(text: $searchText)
        }
    }

    private func deleteList() {
        for task in list.tasksArray {
            NotificationManager.cancelAll(identifier: task.notificationId)
        }
        modelContext.delete(list)
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
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
}

// MARK: - Task row

struct TaskRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Bindable var task: TaskClass
    
    let isListView: Bool
    let tint: Color
    let useGlass: Bool
    let transferableLists: [ListClass]
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onTransfer: (ListClass) -> Void
    
    private var imageGridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible()), count: 5)
    }
    
    @ViewBuilder
    private var taskBackground: some View {
        if isListView && task.list?.backgroundType != "none" && task.list?.glassEffect == false {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.ultraThinMaterial)
        } else if isListView && task.list?.glassEffect == true {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.clear)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24, style: .continuous))
                .allowsHitTesting(false)
        } else {
            Color.clear
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        task.completed = !(task.completed ?? false)
                    }
                    try? modelContext.save()
                    WidgetCenter.shared.reloadAllTimelines()
                } label: {
                    Image(systemName: task.completed == true ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundStyle(tint)
                        .contentTransition(.symbolEffect(.replace))
                        .symbolEffect(.bounce, value: task.completed)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: task.completed)
                }
                .buttonStyle(.plain)
            }
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Text(task.title ?? "Untitled")
                        .fontWeight(.semibold)
                    Spacer()
                    HStack {
                        if horizontalSizeClass != .compact {
                            Button {
                                onEdit()
                            } label: {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(tint)
                            }
                            .buttonStyle(.plain)
                        }
                        if let priority = Priority(rawValue: task.priority ?? "none"), priority != .none {
                            let imageName = priority == .low ? "exclamationmark" : priority == .medium ? "exclamationmark.2" : priority == .high ? "exclamationmark.3" : "exclamationmark.triangle"
                            Image(systemName: imageName)
                                .foregroundStyle(tint)
                                .fontWeight(priority == .critical ? .bold : .regular)
                        }
                        if task.flagged == true {
                            Image(systemName: "flag.fill")
                                .foregroundStyle(tint.gradient)
                                .font(.system(size: 15))
                                .transition(.scale.combined(with: .opacity))
                                .padding(.vertical, 1)
                        }
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: task.flagged)

                if let note = task.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 15))
                }
                if let date = task.date {
                    (
                        Text("\(date.formatted(date: .abbreviated, time: .shortened))")
                        + (task.repeatType != RepeatType.none.rawValue
                            ? Text("  \(Image(systemName: "repeat")) \(repeatLabel(for: task.repeatType))")
                            : Text(""))
                    )
                    .font(.system(size: 15))
                    .fixedSize(horizontal: false, vertical: true)
                }
                if let urlString = task.url, let url = validatedURL(from: urlString) {
                    Link(destination: url) {
                        HStack(spacing: 6) {
                            if let favicon = faviconURL(for: url) {
                                AsyncImage(url: favicon) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                } placeholder: {
                                    Image(systemName: "globe")
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 16, height: 16)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                            }

                            Text(url.host ?? urlString)
                                .font(.system(size: 15))
                                .foregroundStyle(tint)
                                .underline()
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }

                if let images = task.images, !images.isEmpty {
                    LazyVGrid(columns: imageGridColumns, spacing: 8) {
                        ForEach(Array(images.enumerated()), id: \.offset) { index, data in
                            if let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: 40)
                                    .frame(maxHeight: 40)
                                    .cornerRadius(8)
                                    .clipped()
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(taskBackground)
        .swipeActions(edge: .leading) {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }.tint(.blue)
            Button {
                task.flagged = !(task.flagged ?? false)
                try? modelContext.save()
            } label: {
                Label(task.flagged == true ? "Unflag" : "Flag", systemImage: task.flagged == true ? "flag.slash.fill" : "flag.fill")
            }.tint(.orange)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            ControlGroup {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button {
                    task.flagged = !(task.flagged ?? false)
                    try? modelContext.save()
                } label: {
                    Label(task.flagged == true ? "Unflag" : "Flag", systemImage: task.flagged == true ? "flag.slash.fill" : "flag.fill")
                }
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            Button {
                task.completed = !(task.completed ?? false)
                try? modelContext.save()
                WidgetCenter.shared.reloadAllTimelines()
            } label: {
                Label(task.completed == true ? "Mark as incomplete" : "Mark as complete", systemImage: task.completed == true ? "circle" : "checkmark.circle.fill")
            }
            Picker(selection: Binding(
                get: { Priority(rawValue: task.priority ?? "none") ?? .none },
                set: { newValue in
                    task.priority = newValue.rawValue
                    try? modelContext.save()
                }
            )) {
                Text("None").tag(Priority.none)
                Divider()
                Text("Low").tag(Priority.low)
                Text("Medium").tag(Priority.medium)
                Text("High").tag(Priority.high)
                Text("Critical").tag(Priority.critical)
            } label: {
                Label("Priority", systemImage: "exclamationmark.triangle")
            }
            .pickerStyle(.menu)
            if !transferableLists.isEmpty {
                Menu {
                    ForEach(transferableLists) { destination in
                        Button {
                            onTransfer(destination)
                        } label: {
                            Text(destination.title ?? "Untitled")
                        }
                    }
                } label: {
                    Label("Transfer Task", systemImage: "arrow.left.arrow.right")
                }
            }
        }
    }
}

// MARK: - Helpers

func listColor(from name: String) -> Color {
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

private func repeatLabel(for raw: String?) -> String {
    guard let type = RepeatType(rawValue: raw ?? "none"), type != .none else {
        return ""
    }
    let display: String
    switch type {
    case .none:              return ""
    case .hourly:            display = "Hourly"
    case .daily:             display = "Daily"
    case .weekdays:          display = "Weekdays"
    case .weekends:          display = "Weekends"
    case .weekly:            display = "Weekly"
    case .biweekly:          display = "Biweekly"
    case .monthly:           display = "Monthly"
    case .everyThreeMonths:  display = "Every 3 Months"
    case .everySixMonths:    display = "Every 6 Months"
    case .yearly:            display = "Yearly"
    }
    return "\(display)"
}

private func validatedURL(from string: String) -> URL? {
    var trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    if !trimmed.lowercased().hasPrefix("http://") && !trimmed.lowercased().hasPrefix("https://") {
        trimmed = "https://" + trimmed
    }

    guard let components = URLComponents(string: trimmed),
          let scheme = components.scheme, ["http", "https"].contains(scheme),
          let host = components.host, host.contains(".") else {
        return nil
    }

    return components.url
}

private func faviconURL(for url: URL) -> URL? {
    guard let host = url.host else { return nil }
    return URL(
        string: "https://www.google.com/s2/favicons?sz=64&domain=\(host)"
    )
}

private func priorityRank(_ raw: String?) -> Int {
    switch Priority(rawValue: raw ?? "none") ?? .none {
    case .critical: return 4
    case .high:     return 3
    case .medium:   return 2
    case .low:      return 1
    case .none:     return 0
    }
}

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: - Timeline Entry

struct TodayEntry: TimelineEntry {
    let date: Date
    let overdueTasks: [TaskSnapshot]
    let todayTasks: [TaskSnapshot]
    let selectedListTitle: String?  // nil = "Today" mode (all lists)

    var totalCount: Int { overdueTasks.count + todayTasks.count }
}

// MARK: - Task Snapshot

struct TaskSnapshot: Identifiable {
    let id: String
    let title: String
    let priority: String
    let isFlagged: Bool
    let listTitle: String
    let listColor: String
    let isOverdue: Bool
    let persistentID: String  // JSON-encoded PersistentIdentifier for ToggleTaskIntent
}

extension TaskSnapshot {
    init(task: TaskClass, isOverdue: Bool) {
        self.id = "\(task.title ?? "")-\(task.date?.timeIntervalSinceReferenceDate ?? 0)-\(task.persistentModelID)"
        self.title = task.title ?? "Untitled"
        self.priority = task.priority ?? "none"
        self.isFlagged = task.flagged ?? false
        self.listTitle = task.list?.title ?? ""
        self.listColor = task.list?.color ?? "blue"
        self.isOverdue = isOverdue
        if let data = try? JSONEncoder().encode(task.persistentModelID),
           let str = String(data: data, encoding: .utf8) {
            self.persistentID = str
        } else {
            self.persistentID = ""
        }
    }
}

// MARK: - Provider

struct TodayProvider: AppIntentTimelineProvider {
    typealias Intent = ConfigurationAppIntent

    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(
            date: .now,
            overdueTasks: [
                TaskSnapshot(id: "p0", title: "Call dentist", priority: "high",
                             isFlagged: true, listTitle: "Health", listColor: "red",
                             isOverdue: true, persistentID: "")
            ],
            todayTasks: [
                TaskSnapshot(id: "p1", title: "Buy groceries", priority: "none",
                             isFlagged: false, listTitle: "Shopping", listColor: "green",
                             isOverdue: false, persistentID: ""),
                TaskSnapshot(id: "p2", title: "Team standup", priority: "medium",
                             isFlagged: false, listTitle: "Work", listColor: "blue",
                             isOverdue: false, persistentID: "")
            ],
            selectedListTitle: nil
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> TodayEntry {
        context.isPreview ? placeholder(in: context) : loadEntry(listTitle: configuration.list?.id)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<TodayEntry> {
        let entry = loadEntry(listTitle: configuration.list?.id)
        // Reload at midnight so the date buckets reset correctly
        let midnight = Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)
        return Timeline(entries: [entry], policy: .after(midnight))
    }

    // MARK: - Data fetch

    private func loadEntry(listTitle: String?) -> TodayEntry {
        guard let container = makeWidgetContainer() else {
            return TodayEntry(date: .now, overdueTasks: [], todayTasks: [], selectedListTitle: listTitle)
        }

        let context = ModelContext(container)
        let startOfToday = Calendar.current.startOfDay(for: .now)
        let endOfToday   = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!

        // Collect candidates — for a specific list, navigate from list→tasks
        // (more reliable than task.list in a widget context)
        let candidates: [TaskClass]
        if let listTitle {
            let allLists = (try? context.fetch(FetchDescriptor<ListClass>())) ?? []
            candidates = allLists.first(where: { $0.title == listTitle })?.tasks ?? []
        } else {
            candidates = (try? context.fetch(FetchDescriptor<TaskClass>())) ?? []
        }

        // Include incomplete tasks that are: undated (no due date) OR due today or earlier (overdue)
        // Future-dated tasks are intentionally excluded — the widget shows what needs attention now.
        let visible = candidates.filter { task in
            guard task.completed != true else { return false }
            guard let date = task.date else { return true }   // no date → always show
            return date < endOfToday                           // today or past → show; future → hide
        }

        let overdue = visible
            .filter { $0.date != nil && $0.date! < startOfToday }
            .sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
            .map { TaskSnapshot(task: $0, isOverdue: true) }

        let today = visible
            .filter { $0.date == nil || $0.date! >= startOfToday }
            .sorted { ($0.date ?? Date.distantFuture) < ($1.date ?? Date.distantFuture) }
            .map { TaskSnapshot(task: $0, isOverdue: false) }

        return TodayEntry(date: .now, overdueTasks: overdue, todayTasks: today, selectedListTitle: listTitle)
    }
}

// MARK: - Color helper

private func widgetColor(_ name: String) -> Color {
    switch name {
    case "red":    return .red
    case "orange": return .orange
    case "yellow": return .yellow
    case "green":  return .green
    case "blue":   return .blue
    case "indigo": return .indigo
    case "pink":   return .pink
    case "brown":  return .brown
    case "mint":   return .mint
    case "teal":   return .teal
    default:       return .blue
    }
}

// MARK: - Root view

struct TodayWidgetView: View {
    var entry: TodayEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(entry: entry)
        case .systemLarge:  LargeWidgetView(entry: entry)
        default:            MediumWidgetView(entry: entry)
        }
    }
}

// MARK: - Small

struct SmallWidgetView: View {
    let entry: TodayEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: entry.selectedListTitle != nil ? "list.bullet" : "calendar")
                Text(entry.selectedListTitle ?? "Today")
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)

            Spacer()

            if entry.totalCount == 0 {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("All done!")
                    .font(.callout.weight(.semibold))
                    .padding(.top, 4)
            } else {
                Text("\(entry.totalCount)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.overdueTasks.isEmpty ? .primary : Color.red)
                Text(entry.totalCount == 1 ? "task" : "tasks")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, -6)

                if let first = entry.overdueTasks.first ?? entry.todayTasks.first {
                    Text(first.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(.top, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

// MARK: - Medium

struct MediumWidgetView: View {
    let entry: TodayEntry

    private var displayTasks: [TaskSnapshot] {
        Array((entry.overdueTasks + entry.todayTasks).prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label(
                    entry.selectedListTitle ?? "Today",
                    systemImage: entry.selectedListTitle != nil ? "list.bullet" : "calendar"
                )
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                Spacer()
                if entry.totalCount > 0 {
                    Text("\(entry.totalCount) remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 10)

            if entry.totalCount == 0 {
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("All caught up!").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(displayTasks) { task in
                        WidgetTaskRow(task: task)
                    }
                    if entry.totalCount > 3 {
                        Text("+ \(entry.totalCount - 3) more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 26)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding()
    }
}

// MARK: - Large

struct LargeWidgetView: View {
    let entry: TodayEntry

    private var overdueLimit: Int { min(entry.overdueTasks.count, 4) }
    private var todayLimit:   Int { min(entry.todayTasks.count, 8 - overdueLimit) }
    private var shownTotal:   Int { overdueLimit + todayLimit }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label(
                    entry.selectedListTitle ?? "Today",
                    systemImage: entry.selectedListTitle != nil ? "list.bullet" : "calendar"
                )
                .font(.headline.weight(.semibold))
                .lineLimit(1)
                Spacer()
                if entry.totalCount > 0 {
                    Text("\(entry.totalCount) remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 12)

            if entry.totalCount == 0 {
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").font(.title3).foregroundStyle(.green)
                    Text("All caught up!").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                if !entry.overdueTasks.isEmpty {
                    Text("OVERDUE")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.red)
                        .padding(.bottom, 6)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(entry.overdueTasks.prefix(overdueLimit))) { task in
                            WidgetTaskRow(task: task)
                        }
                    }
                }

                if !entry.todayTasks.isEmpty {
                    if !entry.overdueTasks.isEmpty {
                        Divider().padding(.vertical, 8)
                        Text(entry.selectedListTitle != nil ? "OTHER" : "TODAY")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 6)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(entry.todayTasks.prefix(todayLimit))) { task in
                            WidgetTaskRow(task: task)
                        }
                    }
                }

                if entry.totalCount > shownTotal {
                    Text("+ \(entry.totalCount - shownTotal) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 6)
                        .padding(.leading, 26)
                }

                Spacer(minLength: 0)
            }
        }
        .padding()
    }
}

// MARK: - Task row

struct WidgetTaskRow: View {
    let task: TaskSnapshot

    private var priorityImage: String? {
        switch task.priority {
        case "low":      return "exclamationmark"
        case "medium":   return "exclamationmark.2"
        case "high":     return "exclamationmark.3"
        case "critical": return "exclamationmark.triangle.fill"
        default:         return nil
        }
    }

    private var priorityColor: Color {
        (task.priority == "high" || task.priority == "critical") ? .red : .orange
    }

    var body: some View {
        HStack(spacing: 8) {
            // Tappable circle — fires ToggleTaskIntent to mark complete
            Button(intent: ToggleTaskIntent(taskPersistentID: task.persistentID)) {
                ZStack {
                    Circle()
                        .strokeBorder(widgetColor(task.listColor), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    if task.isOverdue {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(width: 26, height: 26)   // generous tap target
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.subheadline)
                .lineLimit(1)

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                if task.isFlagged {
                    Image(systemName: "flag.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                if let img = priorityImage {
                    Image(systemName: img)
                        .font(.caption2)
                        .foregroundStyle(priorityColor)
                }
                if !task.listTitle.isEmpty {
                    Circle()
                        .fill(widgetColor(task.listColor))
                        .frame(width: 7, height: 7)
                }
            }
        }
    }
}

// MARK: - Widget definition

struct TodayWidget: Widget {
    let kind = "TodayWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: TodayProvider()
        ) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Tasks")
        .description("See your tasks — pick a list or show what's due today.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

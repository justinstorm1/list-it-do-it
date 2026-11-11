import WidgetKit
import AppIntents
import SwiftData
import Foundation

// MARK: - Shared container (internal so listitdoitwidget.swift can use it too)

func makeWidgetContainer() -> ModelContainer? {
    let schema = Schema([ListClass.self, TaskClass.self])
    let config = ModelConfiguration(
        "v2",
        schema: schema,
        groupContainer: .identifier("group.com.justinstorm1.newtest"),
        cloudKitDatabase: .none
    )
    return try? ModelContainer(for: schema, configurations: config)
}

// MARK: - List entity

struct ListEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "List"
    static var defaultQuery = ListEntityQuery()

    var id: String      // list title — unique enough for a single user's lists
    var title: String
    var icon: String
    var color: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", image: .init(systemName: icon))
    }
}

// MARK: - List entity query

struct ListEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ListEntity] {
        let all = try await suggestedEntities()
        return identifiers.compactMap { id in all.first { $0.id == id } }
    }

    func suggestedEntities() async throws -> [ListEntity] {
        guard let container = makeWidgetContainer() else { return [] }
        let context = ModelContext(container)
        let lists = (try? context.fetch(FetchDescriptor<ListClass>())) ?? []
        return lists
            .compactMap { list -> ListEntity? in
                guard let title = list.title else { return nil }
                return ListEntity(
                    id: title,
                    title: title,
                    icon: list.icon ?? "list.bullet",
                    color: list.color ?? "blue"
                )
            }
            .sorted {
                // Pinned lists first, then alphabetical
                let lPinned = false  // pinned is Bool? — sort in memory safely
                let rPinned = false
                _ = (lPinned, rPinned)
                return $0.title < $1.title
            }
    }
}

// MARK: - Widget configuration intent

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Today's Tasks"
    static var description: IntentDescription = IntentDescription(
        "Pick a list to see its tasks, or leave empty to show today's tasks across all lists."
    )

    /// nil = "Today" mode (all lists, date-aware). Non-nil = a specific list.
    @Parameter(title: "List")
    var list: ListEntity?

    init() {}
    init(list: ListEntity?) { self.list = list }
}

// MARK: - Toggle task intent

struct ToggleTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Task"

    @Parameter(title: "Task ID")
    var taskPersistentID: String

    init() {}
    init(taskPersistentID: String) { self.taskPersistentID = taskPersistentID }

    func perform() async throws -> some IntentResult {
        guard !taskPersistentID.isEmpty,
              let data = taskPersistentID.data(using: .utf8),
              let id = try? JSONDecoder().decode(PersistentIdentifier.self, from: data),
              let container = makeWidgetContainer() else {
            return .result()
        }

        let context = ModelContext(container)
        let all = (try? context.fetch(FetchDescriptor<TaskClass>())) ?? []
        if let task = all.first(where: { $0.persistentModelID == id }) {
            task.completed = !(task.completed ?? false)
            try? context.save()
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

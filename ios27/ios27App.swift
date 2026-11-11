//
//  ios27App.swift
//  ios27
//
//  Created by Justin Storm on 6/20/26.
//

import SwiftUI
import SwiftData

@main
struct ios27App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let container: ModelContainer = {
        let schema = Schema([ListClass.self, TaskClass.self])
        // "v2" creates a fresh store, bypassing the incompatible legacy store
        // from a prior CoreData/SwiftData schema. CloudKit re-syncs the data.
        let config = ModelConfiguration(
            "v2",
            schema: schema,
            groupContainer: .identifier("group.com.justinstorm1.newtest"),
            cloudKitDatabase: .private("iCloud.com.justinstorm1.newtest")
        )
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

//
//  TaskClass.swift
//  ios27
//
//  Created by Justin Storm on 6/24/26.
//

import SwiftData
import SwiftUI

enum Priority: String {
    case none = "none"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

enum RepeatType: String {
    case none = "none"
    case hourly = "hourly"
    case daily = "daily"
    case weekdays = "weekdays"
    case weekends = "weekends"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case everyThreeMonths = "everyThreeMonths"
    case everySixMonths = "everySixMonths"
    case yearly = "yearly"
}

@Model
final class TaskClass {
    var title: String?
    var note: String?
    var url: String?
    var date: Date?
    var repeatType: String?
    var priority: String?
    var images: [Data]?
    var createdAt: Date?
    var completed: Bool?
    var flagged: Bool?
    var notificationId: String?
    var list: ListClass?

    init(
        title: String? = nil,
        note: String? = nil,
        url: String? = nil,
        date: Date? = nil,
        repeatType: String? = nil,
        priority: String? = nil,
        images: [Data]? = nil,
        createdAt: Date? = nil,
        completed: Bool? = nil,
        flagged: Bool? = nil,
        notificationId: String? = nil,
        list: ListClass? = nil
    ) {
        self.title = title
        self.note = note
        self.url = url
        self.date = date
        self.repeatType = repeatType
        self.priority = priority
        self.images = images
        self.createdAt = createdAt
        self.completed = completed
        self.flagged = flagged
        self.notificationId = notificationId
        self.list = list
    }
}

extension TaskClass {
    @discardableResult
    static func create(
        in context: ModelContext,
        title: String,
        note: String? = nil,
        url: String? = nil,
        date: Date? = nil,
        repeatType: String? = nil,
        flagged: Bool = false,
        priority: String? = nil,
        images: [Data]? = nil,
        list: ListClass? = nil,
        notificationId: String? = nil
    ) -> TaskClass {
        let task = TaskClass(
            title: title,
            note: note,
            url: url,
            date: date,
            repeatType: repeatType,
            priority: priority,
            images: images,
            createdAt: Date(),
            flagged: flagged,
            notificationId: notificationId,
            list: list
        )
        context.insert(task)
        return task
    }
}

import Foundation
import SwiftData
import SwiftUI

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

@Model
final class ListClass {
    var icon: String?
    var title: String?
    var notes: String?
    var color: String?
    var order: String?
    var backgroundType: String?
    var color1: String?
    var color2: String?
    var imageData: Data?
    var createdAt: Date?
    var pinned: Bool?
    var locked: Bool?
    var textTrailing: Bool?
    var glassEffect: Bool?
    var gradientAngle: Double?

    @Relationship(deleteRule: .cascade)
    var tasks: [TaskClass]?

    init(
        icon: String? = nil,
        title: String? = nil,
        notes: String? = nil,
        color: String? = nil,
        order: String? = nil,
        backgroundType: String? = nil,
        color1: String? = nil,
        color2: String? = nil,
        imageData: Data? = nil,
        createdAt: Date? = nil,
        pinned: Bool? = nil,
        locked: Bool? = nil,
        textTrailing: Bool? = nil,
        glassEffect: Bool? = nil,
        gradientAngle: Double? = nil
    ) {
        self.icon = icon
        self.title = title
        self.notes = notes
        self.color = color
        self.order = order
        self.backgroundType = backgroundType
        self.color1 = color1
        self.color2 = color2
        self.imageData = imageData
        self.createdAt = createdAt
        self.pinned = pinned
        self.locked = locked
        self.textTrailing = textTrailing
        self.glassEffect = glassEffect
        self.gradientAngle = gradientAngle
    }
}

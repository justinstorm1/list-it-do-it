//
//  ListClass.swift
//  ios27
//
//  Created by Justin Storm on 6/22/26.
//

import SwiftData
import SwiftUI

enum ListSortOrder: String, CaseIterable {
    case newest = "Newest"
    case oldest = "Oldest"
    case aToZ = "A–Z"
    case zToA = "Z–A"
    case date = "Date"
    case priority = "Priority"
}

enum BackgroundType: String {
    case none = "none"
    case gradient = "gradient"
    case image = "image"
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

    // CloudKit requires all relationships to be optional
    @Relationship(deleteRule: .cascade)
    var tasks: [TaskClass]?

    var tasksArray: [TaskClass] { tasks ?? [] }

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

extension ListClass {
    @discardableResult
    static func create(
        in context: ModelContext,
        icon: String,
        title: String,
        notes: String? = nil,
        color: String,
        order: String = ListSortOrder.newest.rawValue,
        pinned: Bool = false,
        locked: Bool = false,
        textTrailing: Bool = false,
        glassEffect: Bool = false,
        backgroundType: String? = nil,
        color1: String? = nil,
        color2: String? = nil,
        gradientAngle: Double? = nil,
        imageData: Data? = nil
    ) -> ListClass {
        let list = ListClass(
            icon: icon,
            title: title,
            notes: notes,
            color: color,
            order: order,
            backgroundType: backgroundType,
            color1: color1,
            color2: color2,
            imageData: imageData,
            createdAt: Date(),
            pinned: pinned,
            locked: locked,
            textTrailing: textTrailing,
            glassEffect: glassEffect,
            gradientAngle: gradientAngle
        )
        context.insert(list)
        return list
    }
}

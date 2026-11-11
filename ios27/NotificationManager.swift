//
//  NotificationManager.swift
//  ios27
//
//  Created by Justin Storm on 6/30/26.
//

import Foundation
import UserNotifications

enum NotificationManager {

    /// Requests notification permission if not already determined. Safe to call repeatedly.
    static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        guard settings.authorizationStatus == .notDetermined else { return }

        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Schedules a notification for the given date and returns the identifier used,
    /// so it can be stored on the task and cancelled/rescheduled later.
    @discardableResult
    static func schedule(title: String, body: String?, date: Date) async -> String? {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return nil
        }

        guard date > Date() else { return nil } // don't schedule for the past

        let content = UNMutableNotificationContent()
        content.title = title
        if let body, !body.isEmpty {
            content.body = body
        }
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            return identifier
        } catch {
            print("Failed to schedule notification: \(error)")
            return nil
        }
    }

    /// Cancels a previously scheduled notification by identifier.
    static func cancel(identifier: String?) {
        guard let identifier else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

extension NotificationManager {
    /// Returns a comma-joined list of notification identifiers (usually one, but
    /// weekdays/weekends schedule multiple requests under one root id).
    static func scheduleRepeating(title: String, body: String?, date: Date, repeatType: RepeatType) async -> String? {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let rootId = UUID().uuidString

        func makeContent() -> UNMutableNotificationContent {
            let content = UNMutableNotificationContent()
            content.title = title
            if let body, !body.isEmpty { content.body = body }
            content.sound = .default
            return content
        }

        func addCalendarRequest(id: String, components: DateComponents, repeats: Bool) async {
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
            let request = UNNotificationRequest(identifier: id, content: makeContent(), trigger: trigger)
            try? await center.add(request)
        }

        func addIntervalRequest(id: String, seconds: TimeInterval) async {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(seconds, 60), repeats: true)
            let request = UNNotificationRequest(identifier: id, content: makeContent(), trigger: trigger)
            try? await center.add(request)
        }

        switch repeatType {
        case .none:
            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            await addCalendarRequest(id: rootId, components: comps, repeats: false)
            return rootId

        case .hourly:
            let comps = calendar.dateComponents([.minute, .second], from: date)
            await addCalendarRequest(id: rootId, components: comps, repeats: true)
            return rootId

        case .daily:
            let comps = calendar.dateComponents([.hour, .minute, .second], from: date)
            await addCalendarRequest(id: rootId, components: comps, repeats: true)
            return rootId

        case .weekly:
            var comps = calendar.dateComponents([.hour, .minute, .second], from: date)
            comps.weekday = calendar.component(.weekday, from: date)
            await addCalendarRequest(id: rootId, components: comps, repeats: true)
            return rootId

        case .weekdays:
            var ids: [String] = []
            for weekday in 2...6 { // Mon–Fri
                var comps = calendar.dateComponents([.hour, .minute, .second], from: date)
                comps.weekday = weekday
                let id = "\(rootId)-\(weekday)"
                await addCalendarRequest(id: id, components: comps, repeats: true)
                ids.append(id)
            }
            return ids.joined(separator: ",")

        case .weekends:
            var ids: [String] = []
            for weekday in [1, 7] { // Sun, Sat
                var comps = calendar.dateComponents([.hour, .minute, .second], from: date)
                comps.weekday = weekday
                let id = "\(rootId)-\(weekday)"
                await addCalendarRequest(id: id, components: comps, repeats: true)
                ids.append(id)
            }
            return ids.joined(separator: ",")

        case .monthly:
            // Fires on the same day-of-month, exact, no drift — unlike the
            // interval-based cases below. Caveat: if `date` falls on day 29–31,
            // UNCalendarNotificationTrigger simply won't fire in months that don't
            // have that day (e.g. day 31 skips April, June, Sept, Nov).
            var comps = calendar.dateComponents([.hour, .minute, .second], from: date)
            comps.day = calendar.component(.day, from: date)
            await addCalendarRequest(id: rootId, components: comps, repeats: true)
            return rootId

        case .yearly:
            let comps = calendar.dateComponents([.month, .day, .hour, .minute, .second], from: date)
            await addCalendarRequest(id: rootId, components: comps, repeats: true)
            return rootId

        // UNCalendarNotificationTrigger has no native "every N weeks/months" repeat,
        // so these use a fixed-interval trigger instead. Interval starts counting
        // from whenever the notification is scheduled, so the very first fire won't
        // land exactly on `date` if `date` is far off — it'll fire `seconds` later.
        case .biweekly:
            await addIntervalRequest(id: rootId, seconds: 14 * 24 * 3600)
            return rootId

        case .everyThreeMonths:
            return await scheduleMonthlyInterval(months: 3, title: title, body: body, from: date, rootId: rootId, calendar: calendar, addCalendarRequest: addCalendarRequest)

        case .everySixMonths:
            return await scheduleMonthlyInterval(months: 6, title: title, body: body, from: date, rootId: rootId, calendar: calendar, addCalendarRequest: addCalendarRequest)
        }
    }
    
    private static func scheduleMonthlyInterval(
        months: Int,
        title: String,
        body: String?,
        from date: Date,
        rootId: String,
        calendar: Calendar,
        addCalendarRequest: (String, DateComponents, Bool) async -> Void
    ) async -> String {
        var ids: [String] = []
        let occurrenceCount = 8 // e.g. 2 years of every-3-months, or 4 years of every-6-months

        for i in 0..<occurrenceCount {
            guard let occurrenceDate = calendar.date(byAdding: .month, value: months * i, to: date) else { continue }
            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: occurrenceDate)
            let id = "\(rootId)-\(i)"
            await addCalendarRequest(id, comps, false) // each fires once, at its own exact date
            ids.append(id)
        }

        return ids.joined(separator: ",")
    }
    
    static func cancelAll(identifier: String?) {
        guard let identifier else { return }
        let ids = identifier.split(separator: ",").map(String.init)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}


//
//  EditTaskView.swift
//  ios27
//
//  Created by Justin Storm on 6/30/26.
//

import SwiftUI
import SwiftData
import PhotosUI

struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var list: ListClass
    var task: TaskClass

    @State private var title = ""
    @State private var note = ""
    @State private var url = ""

    @State private var dateEnabled = false
    @State private var date = Date()
    @State private var repeatType: RepeatType = RepeatType.none

    @State private var flagged = false
    @State private var priority: Priority = .none

    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var existingImagesData: [Data] = []
    @State private var newImagesData: [Data] = []

    private var allImagesData: [Data] {
        existingImagesData + newImagesData
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title, axis: .vertical)
                        .font(.system(size: 22, weight: .bold))
                        .lineLimit(1...5)
                    TextField("Note", text: $note, axis: .vertical)
                        .lineLimit(3...5)
                    TextField("URL", text: $url)
                        .autocapitalization(.none)
                }

                Section {
                    Toggle(isOn: $dateEnabled.animation(.spring(response: 0.4, dampingFraction: 0.8))) {
                        Label("Date", systemImage: "calendar")
                    }
                    if dateEnabled {
                        DatePicker(selection: $date) {
                            Text("Select a date")
                        }
                        .datePickerStyle(.graphical)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    Picker(selection: $repeatType) {
                        Text("None").tag(RepeatType.none)
                        Divider()
                        Text("Hourly").tag(RepeatType.hourly)
                        Text("Daily").tag(RepeatType.daily)
                        Text("Weekdays").tag(RepeatType.weekdays)
                        Text("Weekends").tag(RepeatType.weekends)
                        Text("Weekly").tag(RepeatType.weekly)
                        Text("Biweekly").tag(RepeatType.biweekly)
                        Text("Monthly").tag(RepeatType.monthly)
                        Text("Every 3 Months").tag(RepeatType.everyThreeMonths)
                        Text("Every 6 Months").tag(RepeatType.everySixMonths)
                        Text("Yearly").tag(RepeatType.yearly)
                    } label: {
                        Label("Repeat", systemImage: "repeat")
                    }
                }

                Section {
                    Toggle(isOn: $flagged) {
                        Label("Flagged", systemImage: "flag")
                    }
                    Picker(selection: $priority) {
                        Text("None").tag(Priority.none)
                        Divider()
                        Text("Low").tag(Priority.low)
                        Text("Medium").tag(Priority.medium)
                        Text("High").tag(Priority.high)
                        Text("Critical").tag(Priority.critical)
                    } label: {
                        Label("Priority", systemImage: "exclamationmark.triangle")
                    }
                }

                Section {
                    PhotosPicker(selection: $selectedPhotoItems, matching: .images) {
                        Label("Add Photos", systemImage: "photo.on.rectangle")
                    }

                    if !allImagesData.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(allImagesData.enumerated()), id: \.offset) { index, data in
                                    if let uiImage = UIImage(data: data) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))

                                            Button {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    removeImage(at: index)
                                                }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.white, .black.opacity(0.6))
                                                    .font(.system(size: 18))
                                            }
                                            .padding(4)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .onChange(of: selectedPhotoItems) { _, newItems in
                    Task {
                        var newData: [Data] = []
                        for item in newItems {
                            if let data = try? await item.loadTransferable(type: Data.self) {
                                newData.append(data)
                            }
                        }
                        await MainActor.run {
                            newImagesData = newData
                        }
                    }
                }
            }
            .navigationTitle("Edit Task")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editTask()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(color(from: list.color ?? "blue"))
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                title = task.title ?? ""
                note = task.note ?? ""
                url = task.url ?? ""
                dateEnabled = task.date != nil
                date = task.date ?? Date()
                repeatType = RepeatType(rawValue: task.repeatType ?? "none") ?? .none
                flagged = task.flagged == true
                priority = Priority(rawValue: task.priority ?? "none") ?? .none
                existingImagesData = task.images ?? []
            }
        }
    }

    private func removeImage(at index: Int) {
        if index < existingImagesData.count {
            existingImagesData.remove(at: index)
        } else {
            let newIndex = index - existingImagesData.count
            newImagesData.remove(at: newIndex)
            if newIndex < selectedPhotoItems.count {
                selectedPhotoItems.remove(at: newIndex)
            }
        }
    }

    private func editTask() {
        Task {
            cancelAllNotifications(for: task.notificationId)
            var notificationId: String?

            if dateEnabled {
                await NotificationManager.requestAuthorizationIfNeeded()
                notificationId = await NotificationManager.scheduleRepeating(
                    title: title,
                    body: note.isEmpty ? nil : note,
                    date: date,
                    repeatType: repeatType
                )
            }

            task.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            task.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
            task.url = url.trimmingCharacters(in: .whitespacesAndNewlines)
            task.date = dateEnabled ? date : nil
            task.repeatType = repeatType.rawValue
            task.flagged = flagged
            task.priority = priority.rawValue
            task.images = allImagesData.isEmpty ? nil : allImagesData
            task.notificationId = notificationId

            try? modelContext.save()
            dismiss()
        }
    }

    private func cancelAllNotifications(for notificationId: String?) {
        guard let notificationId else { return }
        let ids = notificationId.split(separator: ",").map(String.init)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
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
}

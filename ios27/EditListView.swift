//
//  EditListView.swift
//  ios27
//
//  Created by Justin Storm on 6/27/26.
//

import SwiftUI
import SwiftData
import PhotosUI

struct EditListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .indigo, .pink, .brown, .mint, .teal, .secondary]

    let icons = [
        // Original set
        "checklist", "star.fill", "heart.fill", "bolt.fill", "flame.fill",
        "leaf.fill", "moon.fill", "sun.max.fill", "cloud.fill", "snowflake",
        "drop.fill", "tornado", "wind", "sparkles", "crown.fill", "trophy.fill",
        "medal.fill", "flag.fill", "bell.fill", "tag.fill", "bookmark.fill",
        "pencil", "paintbrush.fill", "scissors", "hammer.fill", "wrench.fill",
        "cart.fill", "bag.fill", "gift.fill", "camera.fill", "music.note",

        // Productivity / work
        "briefcase.fill", "folder.fill", "doc.fill", "doc.text.fill",
        "clipboard.fill", "calendar", "clock.fill", "alarm.fill", "timer",
        "chart.bar.fill", "chart.pie.fill", "list.bullet.clipboard.fill",
        "list.bullet", "square.and.pencil", "paperclip", "printer.fill",
        "envelope.fill", "tray.fill", "archivebox.fill",

        // Home / lifestyle
        "house.fill", "bed.double.fill", "sofa.fill", "lamp.desk.fill",
        "washer.fill", "refrigerator.fill", "key.fill", "lock.fill",
        "lightbulb.fill", "trash.fill", "paintpalette.fill", "wrench.and.screwdriver.fill",

        // Food & drink
        "fork.knife", "cup.and.saucer.fill", "mug.fill", "wineglass.fill",
        "carrot.fill", "birthday.cake.fill", "takeoutbag.and.cup.and.straw.fill",

        // Travel / transport
        "car.fill", "bus.fill", "airplane", "bicycle", "fuelpump.fill",
        "map.fill", "location.fill", "signpost.right.fill", "globe.americas.fill",
        "suitcase.fill", "tent.fill",

        // Health & fitness
        "heart.text.square.fill", "cross.case.fill", "pills.fill",
        "figure.walk", "figure.run", "dumbbell.fill", "bandage.fill",
        "stethoscope",

        // Nature / weather
        "mountain.2.fill", "tree.fill", "pawprint.fill", "ant.fill",
        "fish.fill", "bird.fill", "moon.stars.fill", "cloud.bolt.fill",
        "cloud.rain.fill", "rainbow",

        // Tech
        "desktopcomputer", "laptopcomputer", "iphone", "ipad", "applewatch",
        "headphones", "speaker.wave.2.fill", "wifi", "antenna.radiowaves.left.and.right",
        "battery.100", "power",

        // Money / shopping
        "dollarsign.circle.fill", "creditcard.fill", "banknote.fill",
        "wallet.pass.fill", "cart.badge.plus", "storefront.fill",

        // Education
        "book.fill", "book.closed.fill", "graduationcap.fill", "pencil.and.ruler.fill",
        "backpack.fill", "text.book.closed.fill",

        // Communication / social
        "message.fill", "phone.fill", "person.fill", "person.2.fill",
        "person.3.fill", "megaphone.fill", "quote.bubble.fill",

        // Symbols / misc
        "star.circle.fill", "checkmark.circle.fill", "xmark.circle.fill",
        "exclamationmark.triangle.fill", "questionmark.circle.fill",
        "arrow.triangle.2.circlepath", "infinity", "puzzlepiece.fill",
        "target", "gamecontroller.fill", "theatermasks.fill", "ticket.fill"
    ]

    var list: ListClass

    @State private var selectedIcon = "checklist"
    @State private var title = ""
    @State private var notes = ""
    @State private var selectedColor: Color = .blue
    @State private var isSaving = false
    @State private var errorMessage: String?

    @State private var pinned = false
    @State private var locked = false
    @State private var textTrailing = false
    @State private var glassEffect = false

    @State private var backgroundType: BackgroundType = BackgroundType.none
    @State private var color1: Color = .blue
    @State private var color2: Color = .pink
    @State private var gradientAngle: Double = 180.0
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    private var gradientStartPoint: UnitPoint {
        let radians = (gradientAngle - 90) * .pi / 180
        return UnitPoint(
            x: 0.5 + 0.5 * cos(radians + .pi),
            y: 0.5 + 0.5 * sin(radians + .pi)
        )
    }

    private var gradientEndPoint: UnitPoint {
        let radians = (gradientAngle - 90) * .pi / 180
        return UnitPoint(
            x: 0.5 + 0.5 * cos(radians),
            y: 0.5 + 0.5 * sin(radians)
        )
    }

    let colorColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 7)
    let iconColumns  = Array(repeating: GridItem(.flexible(), spacing: 12), count: 7)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        HStack {
                            Image(systemName: selectedIcon)
                                .font(.system(size: 55))
                                .foregroundStyle(.white)
                                .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: selectedIcon)
                        }
                        .frame(width: 125, height: 125)
                        .background {
                            Circle()
                                .fill(selectedColor.gradient)
                        }
                        Spacer()
                    }

                    TextField("Title", text: $title, axis: .vertical)
                        .lineLimit(1...5)
                        .padding()
                        .font(.system(size: 30, weight: .bold))
                        .multilineTextAlignment(.center)
                        .listRowSeparator(.hidden)
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.secondary.opacity(0.15))
                        }
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...5)

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }

                    LazyVGrid(columns: colorColumns, spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(color.gradient)
                                    .padding(selectedColor == color ? 4 : 0)
                                    .background(
                                        Circle()
                                            .stroke(color, lineWidth: 2)
                                            .opacity(selectedColor == color ? 1 : 0)
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            selectedColor = color
                                        }
                                    }
                            }
                        }
                    }

                    ZStack(alignment: .top) {
                        Text("Scroll to see more icons")
                            .foregroundStyle(.primary)
                            .font(.system(size: 17, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .glassEffect(.regular, in: .rect(cornerRadius: 20))
                            .cornerRadius(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .zIndex(100)
                        ScrollView {
                            LazyVGrid(columns: iconColumns, spacing: 12) {
                                ForEach(icons, id: \.self) { icon in
                                    Circle()
                                        .fill(selectedIcon == icon ? selectedColor : Color.secondary.opacity(0.2))
                                        .overlay {
                                            Image(systemName: icon)
                                                .font(.system(size: 16))
                                                .foregroundStyle(selectedIcon == icon ? .white : .primary)
                                        }
                                        .aspectRatio(1, contentMode: .fit)
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                selectedIcon = icon
                                            }
                                        }
                                }
                            }
                            .padding(.top, 45)
                        }
                    }
                    .frame(height: 500)
                }

                Section {
                    HStack {
                        Spacer()
                        ZStack(alignment: .bottomLeading) {
                            if glassEffect {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.clear)
                                    .glassEffect(.clear.tint(selectedColor), in: .rect(cornerRadius: 20))
                            } else {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedColor.gradient)
                            }

                            Image(systemName: selectedIcon)
                                .font(.system(size: 64))
                                .foregroundStyle(.white.opacity(0.15))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: textTrailing ? .topLeading : .topTrailing)
                                .padding(12)

                            if locked {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: textTrailing ? .bottomLeading : .bottomTrailing)
                                    .padding()
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    if textTrailing {
                                        if pinned {
                                            Image(systemName: "pin.fill")
                                                .font(.title3)
                                                .foregroundStyle(.white)
                                                .rotationEffect(.degrees(45))
                                        }

                                        Spacer()

                                        Image(systemName: selectedIcon)
                                            .font(.title2)
                                            .foregroundStyle(.white)
                                    } else {
                                        Image(systemName: selectedIcon)
                                            .font(.title2)
                                            .foregroundStyle(.white)

                                        Spacer()

                                        if pinned {
                                            Image(systemName: "pin.fill")
                                                .font(.title3)
                                                .foregroundStyle(.white)
                                                .rotationEffect(.degrees(45))
                                        }
                                    }
                                }
                                Spacer()
                                Text(title.isEmpty ? "Untitled" : title)
                                    .lineLimit(1...5)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: textTrailing ? .trailing : .leading)
                                Text("^[\(0) task](inflect: true)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.75))
                                    .frame(maxWidth: .infinity, alignment: textTrailing ? .trailing : .leading)
                            }
                            .padding()
                        }
                        .frame(width: 150, height: 150)
                        Spacer()
                    }
                    Toggle("Pinned", isOn: $pinned)
                        .listRowSeparator(.hidden, edges: .top)
                    Toggle("Locked", isOn: $locked)
                    Toggle("Text Trailing", isOn: $textTrailing)
                    Toggle("Glass Effect", isOn: $glassEffect)
                }

                Section {
                    Picker("Background Type", selection: $backgroundType.animation(.spring(response: 0.4, dampingFraction: 0.8))) {
                        Text("None").tag(BackgroundType.none)
                        Divider()
                        Text("Gradient").tag(BackgroundType.gradient)
                        Text("Image").tag(BackgroundType.image)
                    }
                    if backgroundType == .gradient {
                        VStack(alignment: .center) {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        stops: [
                                            .init(color: color1, location: 0),
                                            .init(color: color2, location: 1)
                                        ],
                                        startPoint: gradientStartPoint,
                                        endPoint: gradientEndPoint
                                    )
                                )
                                .frame(width: 200, height: 200 * 16 / 9)
                                .aspectRatio(9/16, contentMode: .fit)
                            ColorPicker("Color 1", selection: $color1, supportsOpacity: false)
                            ColorPicker("Color 2", selection: $color2, supportsOpacity: false)
                            Slider(value: $gradientAngle, in: 0...359) {
                                Text("Gradient Angle")
                            } minimumValueLabel: {
                                Text("0")
                            } maximumValueLabel: {
                                Text("359")
                            }
                            Text("\(Int(gradientAngle))°")
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    if backgroundType == .image {
                        VStack(alignment: .center) {
                            if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                            }

                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Label("Select Image", systemImage: "photo.on.rectangle")
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit List")
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
                        editList()
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.isEmpty || isSaving)
                }
            }
            .onAppear {
                selectedIcon = list.icon ?? "checklist"
                title = list.title ?? ""
                notes = list.notes ?? ""
                selectedColor = color(from: list.color ?? "blue")
                pinned = list.pinned == true
                locked = list.locked == true
                textTrailing = list.textTrailing == true
                glassEffect = list.glassEffect == true
                backgroundType = BackgroundType(rawValue: list.backgroundType ?? "none") ?? .none
                color1 = Color(hex: list.color1 ?? "#3478F8FF")
                color2 = Color(hex: list.color2 ?? "#FF2D9DFF")
                gradientAngle = list.gradientAngle ?? 180.0
                if let imageData = list.imageData {
                    selectedImageData = imageData
                }
            }
        }
    }

    private func editList() {
        list.icon = selectedIcon
        list.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        list.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        list.color = colorName(for: selectedColor)
        list.pinned = pinned
        list.locked = locked
        list.textTrailing = textTrailing
        list.glassEffect = glassEffect
        list.backgroundType = backgroundType.rawValue
        list.color1 = hexString(for: color1)
        list.color2 = hexString(for: color2)
        list.gradientAngle = gradientAngle
        list.imageData = selectedImageData

        try? modelContext.save()
        dismiss()
    }

    private func hexString(for color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let r = Int(round(red * 255))
        let g = Int(round(green * 255))
        let b = Int(round(blue * 255))
        let a = Int(round(alpha * 255))

        return String(format: "#%02X%02X%02X%02X", r, g, b, a)
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

    private func colorName(for color: Color) -> String {
        switch color {
        case .red:      return "red"
        case .orange:   return "orange"
        case .yellow:   return "yellow"
        case .green:    return "green"
        case .blue:     return "blue"
        case .indigo:   return "indigo"
        case .pink:     return "pink"
        case .brown:    return "brown"
        case .mint:     return "mint"
        case .teal:     return "teal"
        default:        return "secondary"
        }
    }
}

////
////  HomeView.swift
////  ios27
////
////  Created by Justin Storm on 6/20/26.
////
//
//import SwiftUI
//
//struct Item: Identifiable {
//    let id = UUID()
//    var color: Color
//}
//
//extension Array {
//    mutating func apply<CollectionID: Hashable & Sendable>(
//        difference: ReorderDifference<Element.ID, CollectionID>
//    ) where Element: Identifiable, Element.ID: Sendable {
//        guard let sourceIndex = firstIndex(
//            where: { $0.id == difference.sources[0] }
//        ) else { return }
//
//        let movedElement = remove(at: sourceIndex)
//
//        let destination: Int
//        switch difference.destination.position {
//        case let .before(value):
//            guard let index = firstIndex(where: { $0.id == value }) else { return }
//            destination = index
//        case .end:
//            destination = endIndex
//        }
//
//        insert(movedElement, at: destination)
//    }
//}
//
//struct HomeView: View {
//
//    @State private var items = [
//        Item(color: .red),
//        Item(color: .orange),
//        Item(color: .yellow),
//        Item(color: .green),
//        Item(color: .blue),
//        Item(color: .purple),
//    ]
//
//    @State private var searchText: String = ""
//
//    @State private var gaugeValue = 50.0
//    let gaugeGradient = Gradient(colors: [.blue, .purple])
//
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                VStack(spacing: 16) {
//                    ScrollView(.horizontal) {
//                        HStack(spacing: 16) {
//                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
//                                VStack {
//
////                                    HStack {
////                                        Text("Color \(index + 1)")
////                                            .fontWeight(.bold)
////                                            .foregroundStyle(.white)
////                                            .padding()
////                                            .background {
////                                                RoundedRectangle(cornerRadius: 16)
////                                                    .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 16))
////
////                                            }
////                                        Spacer()
////                                    }
////                                    Spacer()
//                                }
//                                .padding()
//                                .frame(width: 150, height: 300)
//                                .background {
//                                    RoundedRectangle(cornerRadius: 20)
//                                        .fill(Color.clear)
//                                        .glassEffect(.clear.interactive().tint(item.color), in: .rect(cornerRadius: 20))
//                                }
//                                .contextMenu {
//                                    ControlGroup {
//                                        Button {
//                                            //
//                                        } label: {
//                                            Label("Folder", systemImage: "folder")
//                                        }
//                                        Button {
//                                            //
//                                        } label: {
//                                            Label("Flag", systemImage: "flag")
//                                        }
//                                        Button(role: .destructive) {
//                                            //
//                                        } label: {
//                                            Label("Delete", systemImage: "trash")
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                        .padding(.horizontal)
//                    }
//                    .scrollIndicators(.hidden)
//
//                    VStack(spacing: 16) {
//                        ForEach(items) { item in
//                            RoundedRectangle(cornerRadius: 16)
//                                .fill(item.color.gradient)
//                                .frame(maxWidth: .infinity)
//                                .frame(height: 200)
//                                .swipeActions {
//                                    Button(role: .destructive) {
//                                        //
//                                    } label: {
//                                        Label("Delete", systemImage: "trash")
//                                    }
//                                }
//                        }
//                        .reorderable()
//                    }
//                    .padding(.horizontal)
//                    .reorderContainer(for: Item.self) { difference in
//                        items.apply(difference: difference)
//                    }
//
//                    Gauge(value: gaugeValue, in: 0...100) {
//                        Text("Battery Level")
//                    } currentValueLabel: {
//                        Text("\(Int(gaugeValue))")
//                    } minimumValueLabel: {
//                        Text("\(0)")
//                    } maximumValueLabel: {
//                        Text("\(100)")
//                    }
//                    .gaugeStyle(.accessoryCircular)
//                    .tint(gaugeGradient)
//
//                }
//            }
//            .swipeActionsContainer()
//            .navigationTitle("Home")
//            .scrollEdgeEffectStyle(.soft, for: .all)
//            .toolbarMinimizeBehavior(.automatic, for: .navigationBar)
//            .searchable(text: $searchText)
//            .toolbar {
//                ToolbarItem {
//                    Menu {
//                        Button {
//                            //
//                        } label: {
//                            Label("Button", systemImage: "square.and.arrow.up")
//                        }
//                    } label: {
//                        Image(systemName: "ellipsis")
//                    }
//                }
//            }
//        }
//    }
//}
//

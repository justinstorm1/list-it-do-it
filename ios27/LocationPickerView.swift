//
//  LocationPickerView.swift
//  ios27
//
//  Created by Justin Storm on 7/7/26.
//


import SwiftUI
import MapKit

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var locationName: String?
    @Binding var latitude: Double?
    @Binding var longitude: Double?
    
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedName: String = ""
    @State private var locationManager = CLLocationManager()
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $cameraPosition) {
                    UserAnnotation()

                    if let selectedCoordinate {
                        Marker(selectedName.isEmpty ? "Selected Location" : selectedName, coordinate: selectedCoordinate)
                            .tint(.red)
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapPitchToggle()
                    MapScaleView()
                }
                .onTapGesture { screenPoint in
                    // Tap-to-drop-pin requires MapReader on iOS 17+
                }
                .ignoresSafeArea(edges: .bottom)
                
                VStack(spacing: 8) {
                    if !searchResults.isEmpty {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(searchResults, id: \.self) { item in
                                    Button {
                                        select(item)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name ?? "Unknown")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.primary)
                                            if let address = item.address?.shortAddress {
                                                Text(address)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(10)
                                    }
                                    Divider()
                                }
                            }
                        }
                        .frame(maxHeight: 220)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search for a place", text: $searchText)
                            .onSubmit { search() }
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                searchResults = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        confirmSelection()
                    } label: {
                        Text("Use This Location")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedCoordinate == nil)
                }
            }
        }
    }
    
    private func search() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        MKLocalSearch(request: request).start { response, _ in
            searchResults = response?.mapItems ?? []
        }
    }
    
    private func select(_ item: MKMapItem) {
        selectedCoordinate = item.location.coordinate
        selectedName = item.name ?? "Selected Location"
        cameraPosition = .region(MKCoordinateRegion(
            center: item.location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
        searchResults = []
        searchText = selectedName
    }
    
    private func useCurrentLocation() {
        locationManager.requestWhenInUseAuthorization()
        if let coordinate = locationManager.location?.coordinate {
            selectedCoordinate = coordinate
            selectedName = "Current Location"
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }
    
    private func confirmSelection() {
        guard let selectedCoordinate else { return }
        latitude = selectedCoordinate.latitude
        longitude = selectedCoordinate.longitude
        locationName = selectedName.isEmpty ? nil : selectedName
        dismiss()
    }
}

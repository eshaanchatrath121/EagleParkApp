//
//  ListingsMapView.swift
//  EaglePark
//
//  Created by Eshaan Chatrath on 12/3/25.
//

import SwiftUI
import MapKit

struct ListingsMapView: View {
    var listingsVM: ListingsViewModel
    
    @State private var selectedSchool = "All"
    
    @State private var mapCameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 42.3355, longitude: -71.1685),
            latitudinalMeters: 3000,
            longitudinalMeters: 3000
        )
    )
    
    @State private var searchText = ""
    @State private var isSearching = false
    
    private var schoolOptions: [String] {
        var names = Set<String>()
        for listing in listingsVM.listings {
            if let schoolName = listing.schoolName, !schoolName.isEmpty {
                names.insert(schoolName)
            }
        }
        return ["All"] + names.sorted()
    }
    
    private func displayName(for schoolKey: String) -> String {
        switch schoolKey {
        case "Boston College": return "BC"
        case "Boston University": return "BU"
        case "Northeastern University": return "NU"
        case "Harvard University": return "Harvard"
        case "Massachusetts Institute of Technology": return "MIT"
        case "All": return "All"
        default: return schoolKey
        }
    }
    
    private var filteredListings: [Listing] {
        listingsVM.listings.filter { listing in
            guard listing.latitude != nil, listing.longitude != nil else { return false }
            if selectedSchool == "All" { return true }
            return listing.schoolName == selectedSchool
        }
    }
    
    private func updateCamera() {
        guard let first = filteredListings.first,
              let lat = first.latitude,
              let lng = first.longitude else { return }
        
        mapCameraPosition = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                latitudinalMeters: 2000,
                longitudinalMeters: 2000
            )
        )
    }
    
    func searchForAddress() {
        guard !searchText.isEmpty else { return }
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        MKLocalSearch(request: request).start { response, error in
            isSearching = false
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
            
            mapCameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: 1500,
                    longitudinalMeters: 1500
                )
            )
        }
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.45, green: 0, blue: 0.07)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                
                HStack {
                    TextField("Search address…", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    Button("Search") {
                        searchForAddress()
                    }
                    .disabled(searchText.isEmpty)
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.87, green: 0.72, blue: 0.22))
                }
                .padding(.top)
                
                if schoolOptions.count > 1 {
                    Picker("School", selection: $selectedSchool) {
                        ForEach(schoolOptions, id: \.self) { key in
                            Text(displayName(for: key)).tag(key)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }
                
                if filteredListings.isEmpty {
                    Text("No listings with map locations.")
                        .foregroundColor(.white.opacity(0.8))
                        .padding()
                } else {
                    Map(position: $mapCameraPosition) {
                        ForEach(filteredListings) { listing in
                            if let lat = listing.latitude,
                               let lng = listing.longitude {
                                
                                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                                
                                Annotation("", coordinate: coord) {
                                    NavigationLink {
                                        ListingDetailView(listing: listing)
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.title)
                                            Text(listing.address)
                                                .font(.caption2)
                                                .padding(4)
                                                .background(.white)
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .mapStyle(.standard(pointsOfInterest: .all))
                    .frame(height: 360)
                    .cornerRadius(12)
                    .padding()
                }
                
                Spacer()
            }
        }
        .navigationTitle("Listings Map")
        .onAppear {
            selectedSchool = "All"
            updateCamera()
        }
        .onChange(of: selectedSchool) { _ in
            updateCamera()
        }
    }
}

#Preview {
    ListingsMapView(listingsVM: ListingsViewModel())
}

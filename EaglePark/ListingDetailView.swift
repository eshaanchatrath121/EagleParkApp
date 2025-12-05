//
//  ListingDetailView.swift
//  EaglePark
//
//  Created by Eshaan Chatrath on 12/1/25.
//

import SwiftUI
import FirebaseAuth
import MapKit

struct ListingDetailView: View {
    let listing: Listing
    @Environment(\.dismiss) private var dismiss
    
    var listingVM = ListingsViewModel()
    
    private let mapDimension: CLLocationDistance = 750.0
    
    private var listingCoordinate: CLLocationCoordinate2D? {
        guard let lat = listing.latitude,
              let lon = listing.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    private var mapCameraPosition: MapCameraPosition? {
        guard let coordinate = listingCoordinate else { return nil }
        return .region(
            MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: mapDimension,
                longitudinalMeters: mapDimension
            )
        )
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.45, green: 0, blue: 0.07)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                
                Text(listing.address)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.87, green: 0.72, blue: 0.22))
                
                Text("Price: \(listing.price.isEmpty ? "N/A" : listing.price)")
                    .font(.title2)
                    .foregroundColor(.white)
                
                if !listing.notes.isEmpty {
                    Text("Notes:")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(listing.notes)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Text("Available: \(listing.isAvailable ? "Yes" : "No")")
                    .font(.title2)
                    .foregroundColor(listing.isAvailable ? .green : .red)
                
                Text("Posted By: \(listing.postedBy)")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.callout)
                
                if let camera = mapCameraPosition,
                   let coord = listingCoordinate {
                    
                    Text("Location")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Map(position: .constant(camera)) {
                        Marker(listing.address, coordinate: coord)
                    }
                    .frame(height: 250)
                    .cornerRadius(12)
                    
                    Text("Lat: \(coord.latitude), Long: \(coord.longitude)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                if userCanDelete {
                    Button("Remove Listing") {
                        listingVM.deleteListing(listing)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.87, green: 0.72, blue: 0.22))
                    .foregroundStyle(.black)
                }
            }
            .padding()
        }
        .navigationTitle("Listing Details")
    }
    
    var userCanDelete: Bool {
        listing.postedBy.lowercased().trimmingCharacters(in: .whitespaces) ==
        (Auth.auth().currentUser?.email ?? "").lowercased()
            .trimmingCharacters(in: .whitespaces)
    }
}

#Preview {
    NavigationStack {
        ListingDetailView(
            listing: Listing(
                id: "test",
                address: "Test Street",
                price: "50",
                notes: "Nice spot",
                isAvailable: true,
                postedBy: "test@bc.edu",
                schoolName: "Boston College",
                latitude: 42.3355,
                longitude: -71.1685
            )
        )
    }
}

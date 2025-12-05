//
//  AddListingView.swift
//  EaglePark
//
//  Created by Eshaan Chatrath on 12/1/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import MapKit

struct AddListingView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var address = ""
    @State private var price = ""
    @State private var notes = ""
    @State private var isAvailable = true
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    @State private var schools: [School] = []
    @State private var selectedSchool: School?
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.3355, longitude: -71.1685),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
    let geocoder = CLGeocoder()
    
    var body: some View {
        ZStack {
            Color(red: 0.45, green: 0, blue: 0.07)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    Text("Add Parking Listing")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.87, green: 0.72, blue: 0.22))
                        .padding(.top)
                    
                    
                    VStack(spacing: 6) {
                        HStack {
                            Spacer()
                            Text("Closest School")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        if schools.isEmpty {
                            Text("Loading schools…")
                                .foregroundColor(.white.opacity(0.7))
                        } else {
                            Menu {
                                Picker("Closest School", selection: $selectedSchool) {
                                    ForEach(schools) { school in
                                        Text(school.name).tag(Optional(school))
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedSchool?.name ?? "Select School")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(10)
                            }
                        }
                    }
                    
                    
                    Map(
                        coordinateRegion: $region,
                        annotationItems: pinAnnotationItems()
                    ) { item in
                        MapMarker(coordinate: item.coordinate)
                    }
                    .frame(height: 250)
                    .cornerRadius(12)
                    
                    
                    VStack(alignment: .leading) {
                        Text("Address (optional)")
                            .foregroundColor(.white)
                        
                        TextField("Type address to move map…", text: $address)
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                    .onChange(of: address) { newValue in
                        geocodeAddress(newValue)
                    }
                    
                    
                    VStack(alignment: .leading) {
                        Text("Price ($/hr)")
                            .foregroundColor(.white)
                        
                        HStack {
                            Text("$").foregroundColor(.white)
                            
                            TextField("Hourly price", text: $price)
                                .keyboardType(.decimalPad)
                                .foregroundColor(.white)
                            
                            Text("/hr").foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(10)
                    }
                    
                    
                    VStack(alignment: .leading) {
                        Text("Notes")
                            .foregroundColor(.white)
                        
                        TextField("Any details…", text: $notes, axis: .vertical)
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .lineLimit(4)
                    }
                    
                    
                    Toggle("Available Now", isOn: $isAvailable)
                        .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.87, green: 0.72, blue: 0.22)))
                        .foregroundColor(.white)
                    
                    
                    Button {
                        submitListing()
                    } label: {
                        Text("Submit Listing")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 0.87, green: 0.72, blue: 0.22))
                            .foregroundColor(.black)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Add Listing")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.87, green: 0.72, blue: 0.22))
            }
        }
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        }
        .onAppear { loadSchools() }
        .onChange(of: selectedSchool) { newSchool in
            if let school = newSchool {
                region.center = CLLocationCoordinate2D(
                    latitude: school.coordinates.lat,
                    longitude: school.coordinates.lng
                )
            }
        }
    }
    
    
    func geocodeAddress(_ input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        geocoder.geocodeAddressString(trimmed) { placemarks, error in
            if let location = placemarks?.first?.location {
                DispatchQueue.main.async {
                    region.center = location.coordinate
                }
            }
        }
    }
    
    
    func pinAnnotationItems() -> [PinLocation] {
        return [PinLocation(coordinate: region.center)]
    }
    
    
    func submitListing() {
        
        let cleanedPrice = price
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "/hr", with: "")
            .replacingOccurrences(of: "hr", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        let db = Firestore.firestore()
        let userEmail = Auth.auth().currentUser?.email ?? "unknown"
        
        let listingData: [String: Any] = [
            "address": address,
            "price": cleanedPrice,
            "notes": notes,
            "isAvailable": isAvailable,
            "postedBy": userEmail,
            "createdAt": Timestamp(),
            "latitude": region.center.latitude,
            "longitude": region.center.longitude,
            "schoolName": selectedSchool?.name ?? ""
        ]
        
        db.collection("listings").addDocument(data: listingData) { error in
            if let error = error {
                alertMessage = error.localizedDescription
                showingAlert = true
            } else {
                dismiss()
            }
        }
    }
    
    
    func loadSchools() {
        guard let url = URL(string: "https://mocki.io/v1/9b6e2e31-8240-4f44-bb1d-f602f5fc2a7e") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                do {
                    let decoded = try JSONDecoder().decode(SchoolResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.schools = decoded.schools
                        
                        if let first = decoded.schools.first {
                            self.selectedSchool = first
                            self.region.center = CLLocationCoordinate2D(
                                latitude: first.coordinates.lat,
                                longitude: first.coordinates.lng
                            )
                        }
                    }
                } catch {
                    print("Decode error:", error)
                }
            }
        }.resume()
    }
}


struct SchoolResponse: Codable {
    let schools: [School]
}

struct School: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let email_domain: String
    let coordinates: Coordinates
    let streets_nearby: [String]
}

struct Coordinates: Codable, Hashable {
    let lat: Double
    let lng: Double
}

struct PinLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}


#Preview {
    NavigationStack { AddListingView() }
}

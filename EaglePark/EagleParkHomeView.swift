//
//  EagleParkHomeView.swift
//  EaglePark
//
//  Created by Eshaan Chatrath on 11/27/25.
//

import SwiftUI
import FirebaseAuth

struct EagleParkHomeView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State var listingsVM = ListingsViewModel()  
    
    @State private var selectedFilter: String = "All"
    @State private var showOnlyMyListings: Bool = false
    
    @State private var priceSortOption: String = "None"
    let priceSortChoices = ["None", "Low → High", "High → Low"]
    
    let schoolFilters = ["All", "BC", "BU", "Northeastern", "Harvard", "MIT"]
    
    func numericPrice(_ price: String) -> Double {
        let digits = price
            .components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted)
            .joined()
        
        return Double(digits) ?? 0.0
    }
    
    func formattedPrice(_ price: String) -> String {
        let clean = price.filter { "0123456789.".contains($0) }
        if clean.isEmpty { return "" }
        return "$\(clean)/hr"
    }

    
    var filteredListings: [Listing] {
        var results = listingsVM.listings.filter { listing in
            
            if showOnlyMyListings {
                if listing.postedBy.lowercased() != (Auth.auth().currentUser?.email ?? "").lowercased() {
                    return false
                }
            }
            
            if selectedFilter != "All" {
                guard let schoolName = listing.schoolName else { return false }
                return normalizeSchoolName(schoolName) == selectedFilter
            }
            
            return true
        }
        
        switch priceSortOption {
        case "Low → High":
            results.sort { numericPrice($0.price) < numericPrice($1.price) }
        case "High → Low":
            results.sort { numericPrice($0.price) > numericPrice($1.price) }
        default:
            break
        }
        
        return results
    }
    
    func normalizeSchoolName(_ name: String) -> String {
        switch name.lowercased() {
        case "boston college": return "BC"
        case "boston university": return "BU"
        case "northeastern university": return "Northeastern"
        case "harvard university": return "Harvard"
        case "massachusetts institute of technology": return "MIT"
        default: return name
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                Color(red: 0.45, green: 0, blue: 0.07)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    
                    Text("Welcome Back!")
                        .font(.title)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        Picker("School Filter", selection: $selectedFilter) {
                            ForEach(schoolFilters, id: \.self) { filter in
                                Text(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        Toggle("My Listings Only", isOn: $showOnlyMyListings)
                            .tint(Color(red: 0.87, green: 0.72, blue: 0.22))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        HStack {
                            Text("Sort by Price:")
                                .foregroundColor(.white)
                            Spacer()
                            Picker("Sort by Price", selection: $priceSortOption) {
                                ForEach(priceSortChoices, id: \.self) { choice in
                                    Text(choice)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color(red: 0.87, green: 0.72, blue: 0.22))
                        }
                        .padding(.horizontal)
                    }
                    
                    if filteredListings.isEmpty {
                        Text("No listings match your filters.")
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top)
                    } else {
                        List {
                            ForEach(filteredListings) { listing in
                                NavigationLink {
                                    ListingDetailView(listing: listing)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            
                                            let displayAddress = listing.address.trimmingCharacters(in: .whitespaces)
                                            
                                            Text(displayAddress.isEmpty ?
                                                 normalizeSchoolName(listing.schoolName ?? "Unknown") :
                                                 displayAddress)
                                                .font(.headline)
                                            
                                            if !listing.price.isEmpty {
                                                Text(formattedPrice(listing.price))
                                                    .font(.subheadline)
                                                    .foregroundColor(.yellow)
                                            }
                                            
                                            if let school = listing.schoolName {
                                                Text(normalizeSchoolName(school))
                                                    .font(.caption)
                                                    .foregroundColor(.yellow.opacity(0.8))
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        if listing.isAvailable {
                                            Text("Available").foregroundColor(.green)
                                        } else {
                                            Text("Not Available").foregroundColor(.red)
                                        }
                                    }
                                    .foregroundColor(.white)
                                }
                                .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                    
                    Spacer()
                }
                .padding()
                
                VStack {
                    Spacer()
                    HStack {
                        Button("Sign Out") {
                            signOut()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.87, green: 0.72, blue: 0.22))
                        .padding(.leading)
                        .foregroundStyle(.black)
                        
                        Spacer()
                        
                        NavigationLink {
                            AddListingView()
                        } label: {
                            Text("Add Listing")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.87, green: 0.72, blue: 0.22))
                        .padding(.trailing)
                        .foregroundStyle(.black)
                    }
                }
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ListingsMapView(listingsVM: listingsVM)
                    } label: {
                        Text("Map View")
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.87, green: 0.72, blue: 0.22))
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            dismiss()
        } catch {
            print("Sign out error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    EagleParkHomeView()
}

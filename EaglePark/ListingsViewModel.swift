//
//  ListingsViewModel.swift
//  EaglePark
//
//  Created by Eshaan Chatrath on 12/1/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Observation

@Observable
class ListingsViewModel {
    var listings: [Listing] = []
    
    private var db = Firestore.firestore()
    
    init() {
        loadData()
    }
    
    func loadData() {
        db.collection("listings")
            .order(by: "address")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ ERROR: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("❌ ERROR: No documents in 'listings' collection")
                    return
                }
                
                var newListings: [Listing] = []
                
                for document in documents {
                    let data = document.data()
                    
                    let listing = Listing(
                        id: document.documentID,
                        address: data["address"] as? String ?? "",
                        price: data["price"] as? String ?? "",
                        notes: data["notes"] as? String ?? "",
                        isAvailable: data["isAvailable"] as? Bool ?? true,
                        postedBy: data["postedBy"] as? String ?? "",
                        schoolName: (data["schoolName"] as? String).flatMap { $0.isEmpty ? nil : $0 },
                        latitude: data["latitude"] as? Double,
                        longitude: data["longitude"] as? Double
                    )
                    
                    newListings.append(listing)
                }
                
                DispatchQueue.main.async {
                    self.listings = newListings
                }
            }
    }
    
    func addListing(address: String, price: String, notes: String, isAvailable: Bool) {
        guard let email = Auth.auth().currentUser?.email else { return }
        
        let data: [String: Any] = [
            "address": address,
            "price": price,
            "notes": notes,
            "isAvailable": isAvailable,
            "postedBy": email
        ]
        
        db.collection("listings").addDocument(data: data) { error in
            if let error = error {
                print("❌ ERROR: Could not add listing \(error.localizedDescription)")
            } else {
                print("✅ Listing added to Firestore")
            }
        }
    }
    
    func deleteListing(_ listing: Listing) {
        guard !listing.id.isEmpty else { return }
        
        db.collection("listings").document(listing.id).delete { error in
            if let error = error {
                print("❌ ERROR: deleting listing \(error.localizedDescription)")
            } else {
                print("🗑️ Listing successfully deleted")
            }
        }
    }
}

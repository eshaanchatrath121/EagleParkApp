//
//  Listing.swift
//  EaglePark
//
//  Created by Eshaan Chatrath on 12/1/25.
//

import Foundation

struct Listing: Identifiable {
    var id: String = ""
    var address: String
    var price: String
    var notes: String
    var isAvailable: Bool
    var postedBy: String
    
    var schoolName: String?
    var latitude: Double?
    var longitude: Double?
}

//
//  Library.swift
//  TesetApp
//
//  Created by Katie Pell on 3/17/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct Library: Identifiable {
    let id = UUID() // Unique identifier for each library
    let mapItem: MKMapItem
    var isVisited: Bool = false

    
    // Convenience properties
    var name: String {
        mapItem.name ?? "Unknown"
    }
    
    var coordinate: CLLocationCoordinate2D {
        mapItem.placemark.coordinate
    }
    
    var placemark: MKPlacemark {
        mapItem.placemark
    }
    
    var address: String {
        return mapItem.placemark.title ?? "No address available"
    }
    
    var latitude: Double {
        return coordinate.latitude
    }
    
    var longitude: Double {
        return coordinate.longitude
    }
    
    
}

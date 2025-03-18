import SwiftUI
import MapKit
import CoreLocation

struct Library: Identifiable, Equatable {
    var id = UUID() // Unique identifier for each library
    var mapItem: MKMapItem
    // Store the 'isVisited' value as a regular property
    private var isVisitedKey: String {
        "isVisited_\(id.uuidString)"
    }
    
    // Stored 'isVisited' property with initialization from UserDefaults
    var isVisited: Bool {
        get {
            // Retrieve the stored value from UserDefaults, default to false
            UserDefaults.standard.bool(forKey: isVisitedKey)
        }
        set {
            // Store the new value in UserDefaults
            UserDefaults.standard.set(newValue, forKey: isVisitedKey)
        }
    }
    
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
    
    // Initializer for Library that initializes the mapItem
    init(mapItem: MKMapItem) {
        self.mapItem = mapItem
    }
    
    // Function to load all libraries from UserDefaults
    static func loadLibraries(from mapItems: [MKMapItem]) -> [Library] {
        return mapItems.map { mapItem in
            var library = Library(mapItem: mapItem)
            library.isVisited = UserDefaults.standard.bool(forKey: "isVisited_\(library.id.uuidString)")
            return library
        }
    }
}

func printLibrary(_ library: Library) {
    print("Library Name: \(library.name)")
    print("Library Coordinate: \(library.coordinate.latitude), \(library.coordinate.longitude)")
    print("Is Visited: \(library.isVisited)")
}

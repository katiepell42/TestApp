import SwiftUI
import MapKit
import CoreLocation

enum AnnotationItem: Identifiable {
    case library(Library)
    case searchedLocation(MKPlacemark)

    var id: UUID {
        switch self {
        case .library(let library):
            return library.id
        case .searchedLocation(let placemark):
            return UUID()
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .library(let library):
            return library.coordinate
        case .searchedLocation(let placemark):
            return placemark.coordinate
        }
    }
}

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var libraryAnnotations: [Library] = [] // Use Library instead of MKMapItem
    @State private var selectedLibrary: Library // Now selectedLibrary is non-optional
    @State private var showingDetailView = false  // State for showing the detail view
    @State private var annotations: [AnnotationItem] = [] // Combined annotations for libraries and searched locations
    @State private var isSearchPerformed: Bool = false
    @State private var pannedLocation: CLLocationCoordinate2D? = nil // Track the panned location

    // Custom initializer to initialize `selectedLibrary`
    init() {
        // Initialize a default MKMapItem
        let defaultPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
        let defaultMapItem = MKMapItem(placemark: defaultPlacemark)
        
        // Initialize selectedLibrary with just the mapItem
        _selectedLibrary = State(initialValue: Library(mapItem: defaultMapItem)) // Only passing mapItem
    }

    var body: some View {
        ZStack {
            if let userLocation = locationManager.userLocation {
                // Combine both library annotations and the searched pin annotation
                let combinedAnnotations = annotations + libraryAnnotations.map { AnnotationItem.library($0) }

                // Display map with user's location and combined annotations
                Map(coordinateRegion: $region,
                    interactionModes: .all,
                    showsUserLocation: true,
                    annotationItems: combinedAnnotations) { annotation in
                        MapAnnotation(coordinate: annotation.coordinate) {
                            switch annotation {
                            case .library(let library):
                                // Custom annotation view for library
                                ZStack {
                                    if library.isVisited {
                                        Circle()
                                            .fill(Color.yellow)
                                            .frame(width: 40, height: 40)

                                        Image(systemName: "book.fill")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(.white)
                                    } else {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 40, height: 40)

                                        Image(systemName: "book.fill")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedLibrary = library
                                    showingDetailView = true
                                }

                            case .searchedLocation(let placemark):
                                // Red pin for searched address
                                Image(systemName: "mappin.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .navigationTitle("Nearby Libraries")
                    .sheet(isPresented: $showingDetailView) {
                        // Directly pass the non-optional Binding<Library>
                        LibraryDetailView(library: $selectedLibrary)
                            .frame(height: UIScreen.main.bounds.height / 2)
                    }
            } else {
                Text("Loading your location...")
                    .padding()
            }

            // Floating "Search Here" button on top of the map
            Button(action: {
                // When clicked, center the map on the panned location (if panned location is available)
                if let pannedLocation = pannedLocation {
                    region.center = pannedLocation
                    findLibrariesAtLocation(pannedLocation) // Fetch libraries near the panned location
                } else if let userLocation = locationManager.userLocation {
                    // If no panned location, use the current location
                    region.center = userLocation.coordinate
                    findLibrariesAtLocation(userLocation.coordinate) // Fetch libraries near current location
                }
            }) {
                Text("Search Here")
                    .font(.subheadline)
                    .bold()
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.bottom, 40) // Padding from the bottom to avoid overlap with the tab bar
            .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 200) // Position at the bottom of the screen

        }
        .onAppear {
            // Update region when the view appears and the user location is available
            if let userLocation = locationManager.userLocation {
                region.center = userLocation.coordinate
            }
        }
        .onChange(of: locationManager.userLocation) { newLocation in
            // Only update the region if it hasn't been manually set by the user
            if pannedLocation == nil {
                if let newLocation = newLocation {
                    region.center = newLocation.coordinate
                }
            }
        }
        .onChange(of: region.center) { newCenter in
            // Track the panned location when the user drags the map
            pannedLocation = newCenter
        }
    }

    // Function to find libraries at a specific location
    func findLibrariesAtLocation(_ coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        searchForNearbyLibraries(userLocation: location) { libraries in
            self.libraryAnnotations = libraries
            // Get the new region for all libraries
            let newRegion = getRegionForAllLibraries()
            // Animate the region change smoothly
            withAnimation(.easeInOut(duration: 1.0)) {
                self.region = newRegion // Update the region smoothly
            }
        }
    }

    // Function to search for nearby libraries at a specific location
    func searchForNearbyLibraries(userLocation: CLLocation, completion: @escaping ([Library]) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "Public Library"
        request.region = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)

        let search = MKLocalSearch(request: request)

        search.start { response, error in
            if let error = error {
                print("Error searching for libraries: \(error.localizedDescription)")
                completion([])
            } else {
                if let mapItems = response?.mapItems {
                    let libraries = mapItems.map { Library(mapItem: $0) } // Map MKMapItems to Library
                    completion(libraries) // Return the libraries
                } else {
                    completion([]) // Return an empty array if no libraries found
                }
            }
        }
    }

    // Function to get the region that encompasses all libraries
    func getRegionForAllLibraries() -> MKCoordinateRegion {
        guard !libraryAnnotations.isEmpty else { return region }

        let latitudes = libraryAnnotations.map { $0.coordinate.latitude }
        let longitudes = libraryAnnotations.map { $0.coordinate.longitude }

        let minLat = latitudes.min() ?? region.center.latitude
        let maxLat = latitudes.max() ?? region.center.latitude
        let minLon = longitudes.min() ?? region.center.longitude
        let maxLon = longitudes.max() ?? region.center.longitude

        let latitudeDelta = maxLat - minLat
        let longitudeDelta = maxLon - minLon

        let center = CLLocationCoordinate2D(latitude: (maxLat + minLat) / 2, longitude: (maxLon + minLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta * 1.2, longitudeDelta: longitudeDelta * 1.2)

        return MKCoordinateRegion(center: center, span: span)
    }

    func updateLibraryAnnotations() {
        // Update the library annotations whenever `isVisited` changes
        self.libraryAnnotations = libraryAnnotations.map { library in
            var updatedLibrary = library
            updatedLibrary.isVisited = updatedLibrary.isVisited // Any additional state update if needed
            return updatedLibrary
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}

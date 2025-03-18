import SwiftUI
import MapKit
import CoreLocation
import Combine

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
    @State private var searchText: String = "" // State for the search text
    @FocusState private var isSearchFocused: Bool // To track the focus state of the search bar
    @State private var keyboardHeight: CGFloat = 0 // To track keyboard height
    @State private var keyboardWillChangeFrameCancellable: AnyCancellable? // To store the publisher
    @State private var librariesLoaded = false // Flag to prevent reloading libraries on every appearance

    init() {
        // Initialize a default MKMapItem
        let defaultPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
        let defaultMapItem = MKMapItem(placemark: defaultPlacemark)
        
        // Initialize selectedLibrary with just the mapItem
        _selectedLibrary = State(initialValue: Library(mapItem: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)))))

        // Start observing the keyboard changes
        self._keyboardWillChangeFrameCancellable = State(initialValue:
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
                .compactMap { notification in
                    (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height
                }
                .sink { [self] height in
                    DispatchQueue.main.async {
                        self.keyboardHeight = height
                    }
                }
        )
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
                                    Circle()
                                        .fill(library.isVisited ? Color.yellow : Color.green)  // Pin color based on isVisited
                                        .frame(width: 35, height: 35)
                                    
                                    Image(systemName: "book.fill")
                                        .resizable()
                                        .frame(width: 15, height: 15)
                                        .foregroundColor(.white)
                                }
                                .contentShape(Rectangle()) // Make the whole annotation tappable
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
                        LibraryDetailView(library: $selectedLibrary)
                            .frame(height: UIScreen.main.bounds.height / 2)
                            .onDisappear {
                                // Force the map to update when the detail view is closed
                                updateLibraryAnnotations()
                            }
                    }
            } else {
                Text("Loading your location...")
                    .padding()
            }

            // Floating "Search Here" button on top of the map
            Button(action: {
                // Clear existing library annotations before fetching new ones
                libraryAnnotations.removeAll()

                // Use the current center of the map (region.center) for the "Search Here" button
                let searchLocation = region.center
                findLibrariesAtLocation(searchLocation) // Fetch libraries at the current map center
            }) {
                Text("Search Here")
                    .font(.subheadline)
                    .bold()
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.bottom, keyboardHeight + 10)
            .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 200)

            // Recenter button
            Button(action: {
                if let userLocation = locationManager.userLocation {
                    // Reset the map to the user's current location
                    region.center = userLocation.coordinate
                }
            }) {
                Image(systemName: "location.fill") // Circular arrow recenter icon
                    .resizable()
                    .frame(width: 25, height: 25) // Adjust the size of the icon
                    .padding() // Add padding to create the circular background
                    .background(Color.white) // White background
                    .foregroundColor(Color.green) // Green foreground for the icon
                    .clipShape(Circle()) // Make the button circular
                    .shadow(radius: 5) // Optional: Add a shadow for a better look
            }
            .padding(.bottom, keyboardHeight + 10) // Adjusted for keyboard height
            .padding(.trailing, 20) // Padding from the right edge
            .position(x: UIScreen.main.bounds.width - 60, y: UIScreen.main.bounds.height - 200) // Position at the bottom-right corner of the map (above navbar)

            // Search Bar
            VStack {
                HStack {
                    TextField("Search for an address", text: $searchText)
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .focused($isSearchFocused)
                        .onSubmit {
                            searchForAddress() // Trigger the search on submit
                        }
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    // Dismiss keyboard when the Done button is tapped
                                    isSearchFocused = false
                                }
                            }
                        }
                        .overlay(
                            HStack {
                                Spacer() // Push the "X" button to the right side
                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = "" // Clear the text when the button is tapped
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.trailing, 8) // Add some spacing on the right inside the field
                                }
                            }
                            .padding(.trailing, 10) // Ensure the "X" is within the padding of the text field
                        )


                    // Magnifying glass button
                    Button(action: {
                        searchForAddress() // Trigger search
                    }) {
                        Image(systemName: "magnifyingglass")
                            .padding() // Adds padding around the magnifying glass icon
                            .background(Color.green) // Set the background color to green
                            .foregroundColor(.white) // Make the icon white
                            .clipShape(Circle()) // Make the button circular
                            .padding(.trailing, 8) // Optional: Add spacing between the button and text field
                    }
                }
                .padding(.top, 40) // Add padding from the top of the screen to position it at the top
                .padding(.horizontal)

                Spacer() // Pushes the search bar to the top of the screen
            }
        }
        .onChange(of: selectedLibrary) { newLibrary in
            // Whenever the selectedLibrary is updated, update the libraryAnnotations array
            updateLibraryAnnotations()
        }
        .onAppear {
            // Load libraries only once
            if !librariesLoaded {
                loadLibraries()
                librariesLoaded = true
            }
            if let userLocation = locationManager.userLocation {
                region.center = userLocation.coordinate
            }
        }
    }

    // Function to search for the address and update the map's region
    func searchForAddress() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(searchText) { (placemarks, error) in
            if let placemark = placemarks?.first {
                if let location = placemark.location {
                    region.center = location.coordinate
                    // Convert CLPlacemark to MKPlacemark and add to annotations
                    let mkPlacemark = MKPlacemark(placemark: placemark)
                    libraryAnnotations.removeAll()
                    annotations.append(.searchedLocation(mkPlacemark))
                    findLibrariesAtLocation(location.coordinate) // Fetch libraries at the searched location
                }
            }
        }
    }

    // Update library annotations based on search and fetch
    func findLibrariesAtLocation(_ coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        searchForNearbyLibraries(userLocation: location) { newLibraries in
            var updatedLibraries: [Library] = []

            // Loop through new libraries and preserve the isVisited property for existing libraries
            for newLibrary in newLibraries {
                if let existingLibrary = libraryAnnotations.first(where: { $0.id == newLibrary.id }) {
                    // Preserve the isVisited status from existing library and update only coordinates
                    var updatedLibrary = newLibrary
                    updatedLibrary.isVisited = existingLibrary.isVisited // Keep isVisited unchanged
                    updatedLibraries.append(updatedLibrary)
                } else {
                    // Add new library without changing isVisited
                    updatedLibraries.append(newLibrary)
                }
            }

            // Now that the new libraries are updated with isVisited preserved, update the libraryAnnotations
            libraryAnnotations = updatedLibraries

            // Update the region to fit all libraries
            let newRegion = getRegionForAllLibraries()
            withAnimation(.easeInOut(duration: 1.0)) {
                self.region = newRegion
            }
        }
    }




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
                    let libraries = mapItems.map { Library(mapItem: $0) }
                    completion(libraries)
                } else {
                    completion([])
                }
            }
        }
    }

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
        // Force the update of library annotations when selectedLibrary changes
        if let index = libraryAnnotations.firstIndex(where: { $0.id == selectedLibrary.id }) {
            libraryAnnotations[index] = selectedLibrary
        }
    }

    func loadLibraries() {
        // Load libraries from UserDefaults when the app starts
        libraryAnnotations = Library.loadLibraries(from: []) // Placeholder: Replace with actual MKMapItems you have
    }
}

import SwiftUI
import MapKit

struct LibraryDetailView: View {
    @Binding var library: Library // Use a binding to update the library directly
    @State private var showingActionSheet = false
    @State private var isVisitedLocal: Bool  // Use @State to track the visited status locally

    // Initialize with the current `isVisited` state from the binding
    init(library: Binding<Library>) {
        _library = library
        _isVisitedLocal = State(initialValue: library.wrappedValue.isVisited) // Initialize local state
    }

    func markAsVisited() {
        isVisitedLocal.toggle()  // Toggle the local visited status
        library.isVisited = isVisitedLocal // Update the parent's state via the binding
        printLibrary(library)  // Log library information
    }

    var body: some View {
        VStack(spacing: 20) {
            // Library Name
            Text(library.name)
                .font(.largeTitle)
                .bold()
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .padding()
                .fixedSize(horizontal: false, vertical: true) // Prevent truncation and allow wrapping
                .frame(maxWidth: .infinity)

            // Library Address
            Text(library.address)
                .font(.body)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding()

            // Get Directions Button
            Button(action: {
                showingActionSheet.toggle() // Show the action sheet
            }) {
                Text("Get Directions")
                    .font(.title2)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.bottom)
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(
                    title: Text("Choose a Map"),
                    message: Text("Select which map you want to use for directions"),
                    buttons: [
                        .default(Text("Apple Maps")) {
                            let destination = MKMapItem(placemark: MKPlacemark(coordinate: library.coordinate))
                            destination.name = library.name
                            destination.openInMaps(launchOptions: [
                                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                            ])
                        },
                        .default(Text("Google Maps")) {
                            let googleMapsURL = URL(string: "comgooglemaps://?daddr=\(library.coordinate.latitude),\(library.coordinate.longitude)&directionsmode=driving")!
                            if UIApplication.shared.canOpenURL(googleMapsURL) {
                                UIApplication.shared.open(googleMapsURL)
                            } else {
                                let webGoogleMapsURL = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(library.coordinate.latitude),\(library.coordinate.longitude)&travelmode=driving")!
                                UIApplication.shared.open(webGoogleMapsURL)
                            }
                        },
                        .cancel()
                    ]
                )
            }

            // Mark as Visited Button
            Button(action: {
                markAsVisited()  // Toggle visited status
            }) {
                Text(isVisitedLocal ? "Unmark as Visited" : "Mark as Visited")
                    .font(.title2)
                    .padding()
                    .background(isVisitedLocal ? Color.yellow : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)

            Spacer()
        }
        .navigationTitle("Library Details")
        .padding()
        .frame(height: UIScreen.main.bounds.height / 2) // Take up half of the screen height
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct LibraryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a sample Library object to use in the preview
        LibraryDetailView(library: .constant(Library(mapItem: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))))))
    }
}

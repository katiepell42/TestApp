import SwiftUI
import MapKit

struct LibraryDetailView: View {
    @Binding var library: Library // Use a binding to update the library directly
    @State private var showingActionSheet = false

    // Function to update the pin style when a library is marked as visited
    func updatePinStyle() {
        // Automatically update the pin style based on visited status
        if library.isVisited {
            // Logic to update the pin to yellow with a book icon (handle this in your map view)
            print("Library marked as visited. Update pin style here.")
        } else {
            // Logic to reset the pin to default style (handle this in your map view)
            print("Library unmarked as visited. Reset pin style here.")
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Library Name
            Text(library.name)
                .font(.largeTitle)
                .bold()
                .lineLimit(nil)
                .multilineTextAlignment(.center)
                .padding()

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
                library.isVisited.toggle() // Toggle visited status
                updatePinStyle()  // Update pin style based on visited status
            }) {
                Text(library.isVisited ? "Unmark as Visited" : "Mark as Visited")
                    .font(.title2)
                    .padding()
                    .background(library.isVisited ? Color.yellow : Color.green)
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
        LibraryDetailView(library: .constant(Library(mapItem: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))))))
    }
}

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            TabView {
                HomeView()
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }
                
                NotifView()
                    .tabItem {
                        Image(systemName: "bell")
                        Text("Notifications")
                    }
                
                MapView()
                    .tabItem {
                        Image(systemName: "map")
                        Text("Map")
                    }
                
                FaveView()
                    .tabItem {
                        Image(systemName: "heart")
                        Text("Favorites")
                    }
                
                ProfileView()
                    .tabItem {
                        Image(systemName: "person.circle")
                        Text("Profile")
                    }
            }
            .accentColor(.green) // Change the focus color of the navigation bar to green
            .onAppear {
                // Customizing the navigation bar appearance when the view appears
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .white // Set background color if needed
                appearance.titleTextAttributes = [.foregroundColor: UIColor.green] // Set the title color to green
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

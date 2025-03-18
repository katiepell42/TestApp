import SwiftUI

struct ContentView: View {
    var body: some View {
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack {
            Text("Home Screen")
                .font(.largeTitle)
            Spacer()
        }
        .padding()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

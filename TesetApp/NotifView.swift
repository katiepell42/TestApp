import SwiftUI

struct NotifView: View {
    var body: some View {
        VStack {
            Text("Notifications Screen")
                .font(.largeTitle)
            Spacer()
        }
        .padding()
    }
}

struct NotifView_Previews: PreviewProvider {
    static var previews: some View {
        NotifView()
    }
}

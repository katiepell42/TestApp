import SwiftUI

struct FaveView: View {
    var body: some View {
        VStack {
            Text("Favorites Screen")
                .font(.largeTitle)
            Spacer()
        }
        .padding()
    }
}

struct FaveView_Previews: PreviewProvider {
    static var previews: some View {
        FaveView()
    }
}

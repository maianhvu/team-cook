import SwiftUI

struct UnderConstructionView: View {
    var body: some View {
        VStack {
            Text("🚧")
                .font(.system(size: 80))
            Text("Under construction")
                .font(.title)
                .fontWeight(.semibold)
            Text("Nothing to see here...")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    UnderConstructionView()
}

//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Feed", systemImage: "newspaper") {
            }
            Tab("Cook", systemImage: "frying.pan") {
                CookRecipesSearchView()
            }
            Tab("Utilities", systemImage: "wrench.and.screwdriver") {
                UnderConstructionView()
            }
            Tab("Profile", systemImage: "person") {
            }
        }
    }
}

#Preview {
    ContentView()
}

//

import SwiftUI

struct ContentView: View {
    @StateObject private var networkClient = NetworkClient(defaultHostname: "localhost:3000", useInsecureHTTP: true)
    
    var body: some View {
        TabView {
            Tab("Feed", systemImage: "newspaper") {
                NavigationView {
                    FeedView()
                }
            }
            Tab("Cook", systemImage: "frying.pan") {
                CookRecipesSearchView()
            }
            Tab("Utilities", systemImage: "wrench.and.screwdriver") {
                NavigationView {
                    UnderConstructionView().navigationTitle("Utilities")
                }
            }
            Tab("Profile", systemImage: "person") {
                NavigationView {
                    UnderConstructionView().navigationTitle("Profile")
                }
            }
        }
        .environment(\.networkClient, networkClient)
    }
}

#Preview {
    ContentView()
}

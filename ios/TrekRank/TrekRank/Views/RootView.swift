import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        Group {
            if session.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
    }
}

struct MainTabView: View {
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            FeedView()
                .tabItem { Label("Feed", systemImage: "list.bullet.rectangle") }
                .tag(0)
            LeaderboardView()
                .tabItem { Label("Ranks", systemImage: "trophy") }
                .tag(1)
            TripsView(goToFeed: { tab = 0 })
                .tabItem { Label("Trips", systemImage: "airplane") }
                .tag(2)
            MapView()
                .tabItem { Label("Map", systemImage: "globe") }
                .tag(3)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(4)
        }
    }
}

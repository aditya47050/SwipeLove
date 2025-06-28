import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()

    var body: some View {
        Group {
            if authVM.isSignedIn {
                MainAppView()
                    .environmentObject(authVM)
            } else {
                LoginView()
                    .environmentObject(authVM)
            }
        }
        .animation(.easeInOut, value: authVM.isSignedIn)
    }
}

struct MainAppView: View {
    @EnvironmentObject var authVM: AuthViewModel // Add this to pass authVM to subviews

    var body: some View {
        TabView {
            SwipeDeckView()
                .tabItem {
                    Label("Discover", systemImage: "flame.fill")
                }
                .environmentObject(authVM)

            ChatListView()
                .tabItem {
                    Label("Chats", systemImage: "message.fill")
                }
                .environmentObject(authVM)

            MatchListView()       // <-- Add Matches tab here
                .tabItem {
                    Label("Matches", systemImage: "heart.fill")
                }
                .environmentObject(authVM)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .environmentObject(authVM)
        }
    }
}



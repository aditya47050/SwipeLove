import SwiftUI
import FirebaseFirestore

struct MatchListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var matchManager = MatchManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.white, Color.pink.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                List {
                    if matchManager.matches.isEmpty {
                        Text("No matches yet")
                            .foregroundColor(.gray)
                            .italic()
                            .padding(.vertical, 20)
                    } else {
                        ForEach(matchManager.matches) { match in
                            if let otherUserId = match.participants.first(where: { $0 != authVM.appUser?.id }) {
                                NavigationLink(destination: MatchDetailLoader(otherUserId: otherUserId)) {
                                    MatchRowView(otherUserId: otherUserId, matchedAt: match.matchedAt)
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.clear) // Make list background transparent so gradient shows
            }
            .navigationTitle("Matches")
            .onAppear {
                if let userId = authVM.appUser?.id {
                    matchManager.startListening(for: userId)
                }
            }
            .onDisappear {
                matchManager.stopListening()
            }
        }
    }
}

struct MatchRowView: View {
    let otherUserId: String
    let matchedAt: Date

    @State private var otherUser: AppUser?
    @State private var isLoading = true

    var body: some View {
        HStack(spacing: 12) {
            if let user = otherUser {
                if let uiImage = base64ToImage(user.profileImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.pink)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(String(user.displayName.prefix(1)))
                                .foregroundColor(.white)
                                .font(.title2)
                        )
                }
            } else if isLoading {
                ProgressView()
                    .frame(width: 50, height: 50)
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 50, height: 50)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(otherUser?.displayName ?? "Loading...")
                    .font(.headline)
                Text("Matched on \(matchedAt, formatter: dateFormatter)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.85))  // Slightly transparent white for a soft card feel
                .shadow(color: Color.pink.opacity(0.2), radius: 5, x: 0, y: 2)
        )
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .onAppear(perform: fetchOtherUser)
    }

    func fetchOtherUser() {
        let db = Firestore.firestore()
        db.collection("users").document(otherUserId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user for match row: \(error.localizedDescription)")
                isLoading = false
                return
            }
            guard let data = snapshot?.data(),
                  let user = AppUser(from: data) else {
                isLoading = false
                return
            }
            DispatchQueue.main.async {
                otherUser = user
                isLoading = false
            }
        }
    }
}


struct MatchDetailLoader: View {
    let otherUserId: String
    @State private var otherUser: AppUser?
    @State private var isLoading = true
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white, Color.pink.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Group {
                if let user = otherUser {
                    ChatView(chatUser: user)
                        .navigationTitle(user.displayName)
                        .navigationBarTitleDisplayMode(.inline)
                } else if isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                        .scaleEffect(1.2)
                } else {
                    Text("Failed to load user")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        }
        .onAppear(perform: fetchOtherUser)
    }

    func fetchOtherUser() {
        let db = Firestore.firestore()
        db.collection("users").document(otherUserId).getDocument { snapshot, error in
            if let error = error {
                print("Error loading user: \(error.localizedDescription)")
                isLoading = false
                return
            }
            guard let data = snapshot?.data(),
                  let user = AppUser(from: data) else {
                isLoading = false
                return
            }
            DispatchQueue.main.async {
                otherUser = user
                isLoading = false
            }
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

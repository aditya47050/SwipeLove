import SwiftUI
import FirebaseFirestore

struct ChatListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var chats: [Chat] = []
    private var db = Firestore.firestore()

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.white, Color.pink.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack {
                    AppTitleView()

                    if chats.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray.opacity(0.3))
                            Text("No Chats Yet")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    } else {
                        List(chats) { chat in
                            if let otherUserId = chat.participants.first(where: { $0 != authVM.appUser?.id }) {
                                NavigationLink(destination: ChatDetailLoader(chat: chat, otherUserId: otherUserId)) {
                                    ChatRowView(otherUserId: otherUserId,
                                                lastMessage: chat.lastMessage,
                                                lastMessageTimestamp: chat.lastMessageTimestamp)
                                }
                                .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear(perform: fetchChats)
        }
    }

    func fetchChats() {
        guard let currentUserId = authVM.appUser?.id else { return }

        db.collection("chats")
            .whereField("participants", arrayContains: currentUserId)
            .order(by: "lastMessageTimestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching chats: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                let fetchedChats = documents.compactMap { doc -> Chat? in
                    Chat(id: doc.documentID, data: doc.data())
                }

                DispatchQueue.main.async {
                    self.chats = fetchedChats
                }
            }
    }
}

struct ChatRowView: View {
    let otherUserId: String
    let lastMessage: String
    let lastMessageTimestamp: Date

    @State private var otherUser: AppUser?
    @State private var isLoading = true

    var body: some View {
        HStack(spacing: 16) {
            if let user = otherUser {
                if let image = base64ToImage(user.profileImageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.pink, lineWidth: 2))
                        .shadow(color: Color.pink.opacity(0.5), radius: 5, x: 0, y: 2)
                } else {
                    Circle()
                        .fill(Color.pink.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(Text(user.displayName.prefix(1))
                                    .font(.headline)
                                    .foregroundColor(.pink))
                }
            } else {
                ProgressView()
                    .frame(width: 50, height: 50)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(otherUser?.displayName ?? "Loading...")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            Text(lastMessageTimestamp, style: .time)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 6)
        .onAppear(perform: fetchOtherUser)
    }

    func fetchOtherUser() {
        let db = Firestore.firestore()
        db.collection("users").document(otherUserId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user: \(error.localizedDescription)")
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


struct ChatDetailLoader: View {
    let chat: Chat
    let otherUserId: String
    @State private var otherUser: AppUser?
    @State private var isLoading = true
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if let user = otherUser {
                ChatView(chatUser: user)
            } else if isLoading {
                ProgressView("Loading...")
            } else {
                Text("Failed to load user")
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





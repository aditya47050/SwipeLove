import SwiftUI
import FirebaseFirestore

struct ChatView: View {
    let chatUser: AppUser
    @EnvironmentObject var authVM: AuthViewModel

    @State private var messages: [Message] = []
    @State private var typedMessage = ""

    private var db = Firestore.firestore()

    private var chatId: String {
        let ids = [authVM.appUser?.id ?? "", chatUser.id].sorted()
        return ids.joined(separator: "_")
    }

    init(chatUser: AppUser) {
        self.chatUser = chatUser
    }

    var body: some View {
        VStack {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(messages) { message in
                            MessageRow(message: message, isCurrentUser: message.senderId == authVM.appUser?.id)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _ in
                    if let lastId = messages.last?.id {
                        withAnimation {
                            scrollProxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            HStack {
                TextField("Type a message...", text: $typedMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(8)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)

                Button(action: sendMessage) {
                    Text("Send")
                        .bold()
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(typedMessage.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .navigationTitle(chatUser.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .background(
            LinearGradient(
                colors: [Color.white, Color.pink.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear(perform: fetchMessages)
    }

    func fetchMessages() {
        db.collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching messages: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }
                let fetchedMessages = documents.compactMap { doc -> Message? in
                    try? doc.data(as: Message.self)
                }

                DispatchQueue.main.async {
                    self.messages = fetchedMessages
                }
            }
    }

    func sendMessage() {
        guard let currentUserId = authVM.appUser?.id else { return }
        let trimmed = typedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let newMessage = Message(senderId: currentUserId,
                                 receiverId: chatUser.id,
                                 text: trimmed,
                                 timestamp: Date())

        do {
            let chatDocRef = db.collection("chats").document(chatId)
            let _ = try chatDocRef.collection("messages")
                .addDocument(from: newMessage)

            chatDocRef.setData([
                "participants": [currentUserId, chatUser.id],
                "lastMessage": trimmed,
                "lastMessageTimestamp": Timestamp(date: Date())
            ], merge: true)

            typedMessage = ""
        } catch {
            print("Error sending message: \(error.localizedDescription)")
        }
    }
}

struct MessageRow: View {
    let message: Message
    let isCurrentUser: Bool

    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            Text(message.text)
                .padding(10)
                .background(isCurrentUser ? Color.pink : Color.gray.opacity(0.3))
                .foregroundColor(isCurrentUser ? .white : .black)
                .cornerRadius(12)
                .frame(maxWidth: 250, alignment: isCurrentUser ? .trailing : .leading)
            if !isCurrentUser { Spacer() }
        }
        .padding(isCurrentUser ? .leading : .trailing, 50)
    }
}

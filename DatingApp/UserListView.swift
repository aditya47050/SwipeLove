import SwiftUI
import FirebaseFirestore

struct UserListView: View {
    @State private var users: [AppUser] = []
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        List(users) { user in
            NavigationLink(destination: ChatView(chatUser: user)) {
                Text(user.displayName)
                    .foregroundColor(user.id == authVM.appUser?.id ? .gray : .primary)
            }
            .disabled(user.id == authVM.appUser?.id) // Disable selecting yourself
        }
        .navigationTitle("Users")
        .onAppear {
            fetchUsers()
        }
    }

    func fetchUsers() {
        let db = Firestore.firestore()
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error.localizedDescription)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            let fetchedUsers = documents.compactMap { doc -> AppUser? in
                AppUser(from: doc.data())
            }
            DispatchQueue.main.async {
                self.users = fetchedUsers
            }
        }
    }
}

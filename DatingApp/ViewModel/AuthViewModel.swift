import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var authUser: FirebaseAuth.User?
    @Published var appUser: AppUser?
    @Published var isSignedIn = false
    @Published var errorMessage: String?

    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    init() {
        setupAuthListener()
    }

    func setupAuthListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { _, user in
            DispatchQueue.main.async {
                self.authUser = user
                self.isSignedIn = user != nil
            }

            if let user = user {
                self.saveUserToFirestoreIfNeeded()
                self.fetchAppUser(uid: user.uid)
            } else {
                DispatchQueue.main.async {
                    self.appUser = nil
                }
            }
        }
    }

    func signUp(email: String, password: String) {
        errorMessage = nil
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.authUser = result?.user
                self.isSignedIn = true
                if let uid = result?.user.uid {
                    self.saveUserToFirestoreIfNeeded()
                    self.fetchAppUser(uid: uid)
                }
            }
        }
    }

    func signIn(email: String, password: String) {
        errorMessage = nil
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.authUser = result?.user
                self.isSignedIn = true
                if let uid = result?.user.uid {
                    self.saveUserToFirestoreIfNeeded()
                    self.fetchAppUser(uid: uid)
                }
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.authUser = nil
                self.appUser = nil
                self.isSignedIn = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func saveUserToFirestoreIfNeeded() {
        guard let user = Auth.auth().currentUser else { return }
        let userRef = db.collection("users").document(user.uid)

        userRef.getDocument { snapshot, error in
            if let error = error {
                print("Error checking user document: \(error.localizedDescription)")
                return
            }

            if snapshot?.exists == false {
                let userData: [String: Any] = [
                    "uid": user.uid,
                    "email": user.email ?? "",
                    "displayName": user.displayName ?? user.email ?? "Unknown",
                    "profileImageURL": "",
                    "profileImageData": ""
                ]
                userRef.setData(userData) { error in
                    if let error = error {
                        print("Error saving user data: \(error.localizedDescription)")
                    } else {
                        print("User data saved successfully")
                    }
                }
            }
        }
    }

    private func fetchAppUser(uid: String) {
        let userRef = db.collection("users").document(uid)
        userRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching app user: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data() else { return }

            if let appUser = AppUser(from: data) {
                DispatchQueue.main.async {
                    self.appUser = appUser
                }
            } else {
                print("Failed to parse app user data")
            }
        }
    }

    // Update profile image base64 string
    func updateProfileImageData(base64String: String, completion: @escaping (Error?) -> Void) {
        guard let userId = authUser?.uid else { return }
        let userRef = db.collection("users").document(userId)

        userRef.updateData(["profileImageData": base64String]) { error in
            DispatchQueue.main.async {
                if error == nil {
                    self.appUser?.profileImageData = base64String
                }
                completion(error)
            }
        }
    }

    // MARK: - Like and Match Logic

    func likeUser(_ likedUser: AppUser, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = authUser?.uid else {
            completion(false)
            return
        }

        let currentUserLikesRef = db.collection("likes").document(currentUserId)
        currentUserLikesRef.setData([likedUser.id: true], merge: true) { error in
            if let error = error {
                print("Error saving like: \(error.localizedDescription)")
                completion(false)
                return
            }

            // Check if likedUser already liked current user (mutual like)
            let likedUserLikesRef = self.db.collection("likes").document(likedUser.id)
            likedUserLikesRef.getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching likedUser likes: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                let likedUserLikes = snapshot?.data() ?? [:]
                let isMutualLike = (likedUserLikes[currentUserId] as? Bool) ?? false

                if isMutualLike {
                    // Create match document
                    let participants = [currentUserId, likedUser.id].sorted()
                    let matchData: [String: Any] = [
                        "participants": participants,
                        "matchedAt": Timestamp(date: Date())
                    ]

                    self.db.collection("matches").addDocument(data: matchData) { error in
                        if let error = error {
                            print("Error creating match: \(error.localizedDescription)")
                            completion(false)
                            return
                        }
                        print("Match created between \(currentUserId) and \(likedUser.id)")
                        completion(true)
                    }
                } else {
                    completion(false)
                }
            }
        }
    }

    func passUser(_ passedUser: AppUser) {
        guard let currentUserId = appUser?.id else { return }
        let currentUserLikesRef = db.collection("likes").document(currentUserId)
        currentUserLikesRef.setData([passedUser.id: false], merge: true) { error in
            if let error = error {
                print("Error saving pass: \(error.localizedDescription)")
            }
        }
    }
}

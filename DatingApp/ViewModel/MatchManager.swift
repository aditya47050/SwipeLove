import Foundation
import FirebaseFirestore

class MatchManager: ObservableObject {
    static let shared = MatchManager()
    private let db = Firestore.firestore()

    @Published var matches: [Match] = []

    private var listener: ListenerRegistration?

    private init() {}

    func startListening(for userId: String) {
        listener?.remove()
        listener = db.collection("matches")
            .whereField("participants", arrayContains: userId)
            .order(by: "matchedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error fetching matches: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                let fetchedMatches = documents.compactMap { doc -> Match? in
                    Match(id: doc.documentID, data: doc.data())
                }
                DispatchQueue.main.async {
                    self.matches = fetchedMatches
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
}

import Foundation
import FirebaseFirestore

struct Match: Identifiable {
    var id: String
    var participants: [String]
    var matchedAt: Date

    init(id: String, data: [String: Any]) {
        self.id = id
        self.participants = data["participants"] as? [String] ?? []
        if let timestamp = data["matchedAt"] as? Timestamp {
            self.matchedAt = timestamp.dateValue()
        } else {
            self.matchedAt = Date()
        }
    }
}

import Foundation
import FirebaseFirestore

struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    let senderId: String
    let receiverId: String
    let text: String
    let timestamp: Date

    init(id: String? = nil, senderId: String, receiverId: String, text: String, timestamp: Date = Date()) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.text = text
        self.timestamp = timestamp
    }
}

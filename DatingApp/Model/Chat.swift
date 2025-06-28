// Chat.swift
import Foundation
import FirebaseFirestore

struct Chat: Identifiable {
    let id: String              // chat document ID = uid1_uid2
    let participants: [String] // 2 UIDs
    let lastMessage: String
    let lastMessageTimestamp: Date

    init?(id: String, data: [String: Any]) {
        guard
            let participants = data["participants"] as? [String],
            let lastMessage = data["lastMessage"] as? String,
            let timestamp = data["lastMessageTimestamp"] as? Timestamp
        else {
            return nil
        }

        self.id = id
        self.participants = participants
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = timestamp.dateValue()
    }
}

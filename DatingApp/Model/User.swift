import Foundation

struct AppUser: Identifiable, Equatable {
    let id: String
    var displayName: String
    var email: String
    var profileImageURL: String?      // Optional, unused now
    var profileImageData: String?     // Base64-encoded profile image

    init(id: String, displayName: String, email: String, profileImageURL: String? = nil, profileImageData: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.profileImageURL = profileImageURL
        self.profileImageData = profileImageData
    }

    init?(from dict: [String: Any]) {
        guard let uid = dict["uid"] as? String,
              let email = dict["email"] as? String,
              let displayName = dict["displayName"] as? String else {
            return nil
        }

        self.id = uid
        self.displayName = displayName
        self.email = email
        self.profileImageURL = dict["profileImageURL"] as? String
        self.profileImageData = dict["profileImageData"] as? String
    }
}

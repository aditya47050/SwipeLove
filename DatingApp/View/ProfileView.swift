import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showEditView = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.pink.opacity(0.3), Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    if let user = authVM.appUser {
                        VStack(spacing: 20) {
                            // Profile Image or Placeholder
                            if let image = base64ToImage(user.profileImageData) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 140)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 140, height: 140)
                                    .overlay(
                                        Text(user.displayName.prefix(1))
                                            .font(.system(size: 64, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }

                            // Display Name
                            Text(user.displayName)
                                .font(.title)
                                .fontWeight(.heavy)

                            // Email
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            // Buttons
                            VStack(spacing: 16) {
                                Button(action: { showEditView = true }) {
                                    Text("Edit Profile")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .background(Color.pink)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                        .shadow(color: Color.pink.opacity(0.6), radius: 6, x: 0, y: 3)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)

                                Button(action: { authVM.signOut() }) {
                                    Text("Sign Out")
                                        .foregroundColor(.red)
                                        .fontWeight(.semibold)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 8)
                        .padding(.horizontal)
                    } else {
                        ProgressView("Loading profile...")
                            .scaleEffect(1.2)
                            .padding()
                    }

                    Spacer()
                }
                .padding(.vertical, 30)
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showEditView) {
                ProfileEditView()
                    .environmentObject(authVM)
            }
        }
    }
}

func base64ToImage(_ base64String: String?) -> UIImage? {
    guard let base64String = base64String,
          let imageData = Data(base64Encoded: base64String),
          let image = UIImage(data: imageData) else {
        return nil
    }
    return image
}

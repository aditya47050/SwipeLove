import SwiftUI

struct MatchPopupView: View {
    let currentUser: AppUser
    let matchedUser: AppUser
    @Binding var isPresented: Bool

    @State private var animateHearts = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 32) {
                Text("It's a Match!")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundColor(.white)
                    .shadow(radius: 10)

                HStack(spacing: 40) {
                    userImageView(user: currentUser)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.pink)
                        .scaleEffect(animateHearts ? 1.3 : 1)
                        .animation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: animateHearts)
                    userImageView(user: matchedUser)
                }

                Text("You and \(matchedUser.displayName) liked each other.")
                    .font(.title3)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Text("Keep Swiping")
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(15)
                        .foregroundColor(.pink)
                        .shadow(radius: 5)
                }
                .padding(.horizontal, 40)
            }
            .padding(.vertical, 60)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.pink.opacity(0.9))
                    .shadow(radius: 20)
            )
            .padding(30)
            .onAppear {
                animateHearts = true
            }
        }
    }

    @ViewBuilder
    private func userImageView(user: AppUser) -> some View {
        if let img = base64ToImage(user.profileImageData) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: 140, height: 140)
                .clipShape(Circle())
                .shadow(radius: 10)
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
        } else {
            Circle()
                .fill(Color.gray)
                .frame(width: 140, height: 140)
                .overlay(Text(user.displayName.prefix(1)).font(.largeTitle).foregroundColor(.white))
        }
    }
}

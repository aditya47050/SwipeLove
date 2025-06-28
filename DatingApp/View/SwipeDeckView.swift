import SwiftUI
import FirebaseFirestore

struct SwipeDeckView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var users: [AppUser] = []
    @State private var currentIndex = 0

    @State private var showMatchPopup = false
    @State private var matchedUser: AppUser? = nil

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [Color.pink.opacity(0.15), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                // App Title
                Text("SwipeLove 💖")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.pink, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.top, 48)

                Spacer(minLength: 20)

                if currentIndex < users.count {
                    ZStack {
                        ForEach(users.indices.reversed(), id: \.self) { index in
                            if index >= currentIndex {
                                let user = users[index]
                                SwipeCardView(
                                    user: user,
                                    isTopCard: index == currentIndex && !showMatchPopup,
                                    onRemove: { liked in
                                        handleSwipe(liked: liked)
                                    }
                                )
                                .stacked(at: index - currentIndex, in: users.count - currentIndex)
                                .animation(.spring(), value: currentIndex)
                            }
                        }
                    }
                    .frame(height: 480 + CGFloat(users.count) * 12)
                } else {
                    Text("No more users")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding()
                }

                Spacer(minLength: 20)

                // Swipe Buttons
                HStack(spacing: 60) {
                    Button(action: {
                        swipeCurrentCard(liked: false)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 64, height: 64)
                            .foregroundColor(.red)
                            .shadow(radius: 5)
                    }

                    Button(action: {
                        swipeCurrentCard(liked: true)
                    }) {
                        Image(systemName: "heart.circle.fill")
                            .resizable()
                            .frame(width: 64, height: 64)
                            .foregroundColor(.pink)
                            .shadow(radius: 5)
                    }
                }
                .padding(.bottom, 48)
            }

            if showMatchPopup, let matchedUser = matchedUser {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)

                VStack(spacing: 20) {
                    Text("💖 It's a Match!")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.pink)

                    if let image = base64ToImage(matchedUser.profileImageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 150, height: 150)
                            .overlay(Text(matchedUser.displayName.prefix(1))
                                .font(.system(size: 64))
                                .foregroundColor(.white))
                    }

                    Text(matchedUser.displayName)
                        .font(.title2)
                        .bold()

                    Button(action: {
                        withAnimation {
                            showMatchPopup = false
                        }
                    }) {
                        Text("Done")
                            .bold()
                            .frame(minWidth: 100)
                            .padding()
                            .background(Color.pink)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
                .frame(maxWidth: 300)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 20)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showMatchPopup)
                .zIndex(1)
            }
        }
        .onAppear(perform: fetchUsers)
    }

    func handleSwipe(liked: Bool) {
        guard currentIndex < users.count else { return }
        let swipedUser = users[currentIndex]

        if liked {
            authVM.likeUser(swipedUser) { isMatch in
                if isMatch {
                    matchedUser = swipedUser
                    withAnimation {
                        showMatchPopup = true
                    }
                }
            }
        } else {
            authVM.passUser(swipedUser)
        }

        currentIndex += 1
    }

    func swipeCurrentCard(liked: Bool) {
        // Animate swipe programmatically when buttons pressed
        handleSwipe(liked: liked)
    }

    func fetchUsers() {
        guard let currentUserId = authVM.appUser?.id else { return }

        Firestore.firestore().collection("users")
            .whereField("uid", isNotEqualTo: currentUserId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Fetch error: \(error.localizedDescription)")
                    return
                }

                guard let docs = snapshot?.documents else { return }

                let fetchedUsers = docs.compactMap { doc in
                    AppUser(from: doc.data())
                }

                DispatchQueue.main.async {
                    users = fetchedUsers.shuffled()
                    currentIndex = 0
                }
            }
    }
}

extension View {
    func stacked(at position: Int, in total: Int) -> some View {
        // position = 0 is the top card
        let maxVisibleCards = 3  // max cards to show with scaling and offset
        
        // Clamp position for scale & offset calculation
        let clampedPosition = min(position, maxVisibleCards - 1)
        
        // Scale down factor for each card below top card
        let scaleStep: CGFloat = 0.05
        
        // Vertical offset step (cards peek below)
        let verticalStep: CGFloat = 15
        
        // Calculate scale and offset based on clamped position
        let scale = 1 - (CGFloat(clampedPosition) * scaleStep)
        let yOffset = CGFloat(clampedPosition) * verticalStep
        
        return self
            .scaleEffect(scale)
            .offset(x: 0, y: yOffset)
            .animation(.spring(), value: position)
    }
}

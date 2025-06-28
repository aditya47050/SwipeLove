import SwiftUI

struct SwipeCardView: View {
    let user: AppUser
    var isTopCard: Bool = false
    var onRemove: ((_ liked: Bool) -> Void)? = nil

    @State private var offset = CGSize.zero
    @GestureState private var isDragging = false

    var body: some View {
        VStack(spacing: 0) {
            if let image = base64ToImage(user.profileImageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 320, height: 420)
                    .clipped()
                    .cornerRadius(20)
            } else {
                Color.gray.opacity(0.3)
                    .frame(width: 320, height: 420)
                    .cornerRadius(20)
                    .overlay(
                        Text(user.displayName.prefix(1))
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(.white)
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(user.displayName)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white)
        }
        .frame(width: 320, height: 520)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
        .offset(x: offset.width, y: offset.height)
        .rotationEffect(.degrees(Double(offset.width / 20)))
        .overlay(
            Group {
                if isTopCard {
                    HStack {
                        if offset.width > 30 {
                            VStack {
                                Image(systemName: "heart.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.green)
                                    .opacity(Double(offset.width / 150))
                                Text("LIKE")
                                    .font(.headline)
                                    .bold()
                                    .foregroundColor(.green)
                                    .opacity(Double(offset.width / 150))
                            }
                            .padding(.leading, 20)
                            .rotationEffect(.degrees(-15))
                        }

                        Spacer()

                        if offset.width < -30 {
                            VStack {
                                Image(systemName: "xmark")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 34, height: 34)
                                    .foregroundColor(.red)
                                    .opacity(Double(-offset.width / 150))
                                Text("NOPE")
                                    .font(.headline)
                                    .bold()
                                    .foregroundColor(.red)
                                    .opacity(Double(-offset.width / 150))
                            }
                            .padding(.trailing, 20)
                            .rotationEffect(.degrees(15))
                        }
                    }
                    .padding(.top, 30)
                }
            }
        )
        .gesture(
            isTopCard
                ? DragGesture()
                    .updating($isDragging) { _, state, _ in
                        state = true
                    }
                    .onChanged { gesture in
                        offset = gesture.translation
                    }
                    .onEnded { _ in
                        let dragThreshold: CGFloat = 120
                        if offset.width > dragThreshold {
                            onRemove?(true) // liked
                            resetOffset()
                        } else if offset.width < -dragThreshold {
                            onRemove?(false) // passed
                            resetOffset()
                        } else {
                            offset = .zero
                        }
                    }
                : nil
        )
        .animation(.interactiveSpring(), value: offset)
    }

    private func resetOffset() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            offset = .zero
        }
    }
}


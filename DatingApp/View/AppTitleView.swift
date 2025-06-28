import SwiftUI

struct AppTitleView: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("Swipe")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.pink, Color.red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Love")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.red, Color.pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("💖")
                .font(.system(size: 36))
                .shadow(color: .pink.opacity(0.8), radius: 4, x: 0, y: 2)
        }
        .padding(.top, 30)
        .padding(.bottom, 15)
        .accessibilityAddTraits(.isHeader)
    }
}

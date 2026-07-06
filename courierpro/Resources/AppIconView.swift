import SwiftUI

struct AppIconView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.4, blue: 0.9),
                    Color(red: 0.4, green: 0.2, blue: 0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 4) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 80, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

                Text("COURIER")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(4)

                Text("PRO")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(6)
            }
        }
        .frame(width: 1024, height: 1024)
    }
}

#Preview {
    AppIconView()
        .frame(width: 256, height: 256)
}

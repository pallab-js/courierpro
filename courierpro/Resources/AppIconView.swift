import SwiftUI

struct AppIconView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 8) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)

                Text("CP")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 1024, height: 1024)
    }
}

#Preview {
    AppIconView()
}

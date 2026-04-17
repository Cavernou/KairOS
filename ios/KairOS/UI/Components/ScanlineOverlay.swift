import SwiftUI

struct ScanlineOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            let height = Int(proxy.size.height / 6)
            VStack(spacing: 4) {
                ForEach(0..<max(height, 1), id: \.self) { _ in
                    Rectangle()
                        .fill(KairOSColors.chrome.opacity(0.06))
                        .frame(height: 1)
                    Spacer(minLength: 0)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

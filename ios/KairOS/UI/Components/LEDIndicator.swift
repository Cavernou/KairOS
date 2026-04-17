import SwiftUI

struct LEDIndicator: View {
    let isOn: Bool

    var body: some View {
        Circle()
            .fill(isOn ? KairOSColors.led : KairOSColors.chrome.opacity(0.3))
            .frame(width: 10, height: 10)
    }
}

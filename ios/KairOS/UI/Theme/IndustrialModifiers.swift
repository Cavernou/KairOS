import SwiftUI

struct PanelChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(KairOSColors.background)
            .overlay(
                Rectangle()
                    .stroke(KairOSColors.chrome, lineWidth: 2)
            )
            .overlay(alignment: .topLeading) {
                Text("+")
                    .font(KairOSTypography.header)
                    .foregroundStyle(KairOSColors.chrome)
                    .offset(x: -8, y: -10)
            }
            .overlay(alignment: .topTrailing) {
                Text("+")
                    .font(KairOSTypography.header)
                    .foregroundStyle(KairOSColors.chrome)
                    .offset(x: 8, y: -10)
            }
    }
}

struct HeaderButtonChrome: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(KairOSTypography.microTab)
            .foregroundStyle(KairOSColors.background)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(configuration.isPressed ? KairOSColors.background : KairOSColors.chrome)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(configuration.isPressed ? KairOSColors.led : KairOSColors.grid, lineWidth: 2)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    SoundManager.shared.playClick()
                }
            }
    }
}

extension View {
    func panelChrome() -> some View {
        modifier(PanelChrome())
    }
}

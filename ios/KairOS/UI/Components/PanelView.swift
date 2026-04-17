import SwiftUI

struct PanelView<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("+ \(title)")
                    .font(KairOSTypography.header)
                Spacer()
                LEDIndicator(isOn: true)
            }
            content
        }
        .panelChrome()
    }
}

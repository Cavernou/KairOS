import SwiftUI

struct TabBarView: View {
    @Binding var selection: AppTab
    let mode: LayoutMode

    var body: some View {
        Group {
            if mode.isLandscape {
                HStack(spacing: 10) {
                    row(for: Array(AppTab.allCases.prefix(4)), showBarcode: false)
                    row(for: Array(AppTab.allCases.suffix(3)), showBarcode: true)
                }
            } else {
                VStack(spacing: 10) {
                    row(for: Array(AppTab.allCases.prefix(4)), showBarcode: true)
                    row(for: Array(AppTab.allCases.suffix(3)), showBarcode: false)
                }
            }
        }
    }

    private func row(for tabs: [AppTab], showBarcode: Bool) -> some View {
        HStack(spacing: 8) {
            Text("+")
                .font(KairOSTypography.header)
            ForEach(tabs, id: \.self) { tab in
                Button(tab.label) {
                    selection = tab
                }
                .buttonStyle(HeaderButtonChrome())
                .overlay(alignment: .leading) {
                    if selection == tab {
                        Circle()
                            .fill(KairOSColors.alert)
                            .frame(width: 8, height: 8)
                            .offset(x: -6)
                    }
                }
            }
            Spacer(minLength: 0)
            if showBarcode {
                BarcodeStrip()
                    .frame(width: 140, alignment: .trailing)
            }
            Text("+")
                .font(KairOSTypography.header)
        }
    }
}

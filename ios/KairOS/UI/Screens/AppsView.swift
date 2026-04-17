import SwiftUI

struct AppsView: View {
    var body: some View {
        PanelView(title: "APPS") {
            Text("Bundled panels: Notes, Files, Diagnostics")
                .font(KairOSTypography.header)
            Text("Each app runs inside the manifest-gated KairOS container.")
                .font(KairOSTypography.mono)
        }
    }
}

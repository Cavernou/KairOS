import SwiftUI

struct FilesView: View {
    var body: some View {
        PanelView(title: "FILES") {
            Text("Encrypted file manifests and transfer status will render here.")
                .font(KairOSTypography.mono)
        }
    }
}

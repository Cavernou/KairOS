import SwiftUI

struct ContactsView: View {
    @ObservedObject var cache: LocalCache

    var body: some View {
        PanelView(title: "CONTACTS") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(cache.contacts) { contact in
                    HStack {
                        Text(contact.avatarASCII ?? "[?]")
                            .font(KairOSTypography.mono)
                        VStack(alignment: .leading) {
                            Text(contact.displayName)
                                .font(KairOSTypography.header)
                            Text(contact.id)
                                .font(KairOSTypography.mono)
                        }
                        Spacer()
                        Text(contact.trustStatus.uppercased())
                            .font(KairOSTypography.mono)
                    }
                }
            }
        }
    }
}

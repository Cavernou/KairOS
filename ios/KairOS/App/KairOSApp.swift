import SwiftUI

@main
struct KairOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            if appState.isLoggedIn {
                HomeView()
                    .environmentObject(appState)
            } else {
                ActivationTerminalView(identityManager: appState.identityManager, nodeClient: appState.nodeClient)
                    .environmentObject(appState)
            }
        }
    }
}

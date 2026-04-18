import SwiftUI

@main
struct KairOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            if appState.isLoggedIn {
                HomeView()
                    .environmentObject(appState)
                    .task {
                        await appState.notificationManager.requestPermission()
                    }
            } else {
                ActivationTerminalView(identityManager: appState.identityManager, nodeClient: appState.nodeClient)
                    .environmentObject(appState)
                    .task {
                        await appState.notificationManager.requestPermission()
                    }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            SoundManager.shared.handleScenePhase(newPhase)
        }
    }
}

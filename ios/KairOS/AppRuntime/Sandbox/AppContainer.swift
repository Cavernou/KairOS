import Foundation
import SwiftUI

struct BundledAppContainer: Identifiable, Codable {
    let id: String
    let name: String
    let permissions: [AppPermission]
    let version: String
    let description: String
    let entryView: String // SwiftUI view name for the app's main interface
}

enum AppRuntimeTab: String, CaseIterable {
    case run = "Run"
    case info = "Info"
    case data = "Data"
    case settings = "Settings"
}

struct AppTabView: View {
    let app: BundledAppContainer
    @Binding var selectedTab: AppRuntimeTab
    @EnvironmentObject private var kairOSAPI: KairOSAPIImpl
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Group {
                AnyView(loadAppView(named: app.entryView))
                    .tabItem {
                        Label("Run", systemImage: "play.fill")
                    }
                    .tag(AppRuntimeTab.run)
            }
            
            InfoTab(app: app)
                .tabItem {
                    Label("Info", systemImage: "info.circle")
                }
                .tag(AppRuntimeTab.info)
            
            DataTab(app: app)
                .tabItem {
                    Label("Data", systemImage: "folder")
                }
                .tag(AppRuntimeTab.data)
            
            SettingsTab(app: app)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(AppRuntimeTab.settings)
        }
    }
    
    private func loadAppView(named: String) -> some View {
        // In a real implementation, this would dynamically load the view
        // For MVP, apps are compiled into the binary
        return Text("App: \(named)")
    }
}

struct InfoTab: View {
    let app: BundledAppContainer
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(app.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version \(app.version)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider()
                
                Text(app.description)
                    .font(.body)
                
                Divider()
                
                Text("Permissions")
                    .font(.headline)
                
                ForEach(app.permissions, id: \.self) { permission in
                    Text("• \(permission.rawValue)")
                        .font(.body)
                }
            }
            .padding()
        }
        .navigationTitle("Info")
    }
}

struct DataTab: View {
    let app: BundledAppContainer
    @EnvironmentObject private var kairOSAPI: KairOSAPIImpl
    @State private var appFiles: [String] = []
    
    var body: some View {
        List {
            if appFiles.isEmpty {
                Text("No files")
                    .foregroundColor(.secondary)
            } else {
                ForEach(appFiles, id: \.self) { file in
                    Text(file)
                }
            }
        }
        .navigationTitle("Data")
        .onAppear {
            loadAppFiles()
        }
    }
    
    private func loadAppFiles() {
        // List app-local files
        // Files are prefixed with app.id
        let allFiles = kairOSAPI.listFiles()
        appFiles = allFiles.filter { $0.hasPrefix("\(app.id).") }
            .map { $0.replacingOccurrences(of: "\(app.id).", with: "") }
    }
}

struct SettingsTab: View {
    let app: BundledAppContainer
    @State private var permissionStates: [AppPermission: Bool] = [:]
    
    var body: some View {
        List {
            ForEach(AppPermission.allCases, id: \.self) { permission in
                Toggle(isOn: Binding(
                    get: { permissionStates[permission, default: app.permissions.contains(permission)] },
                    set: { newValue in
                        permissionStates[permission] = newValue
                    }
                )) {
                    Text(permission.rawValue.capitalized)
                }
                .disabled(!app.permissions.contains(permission)) // Can't enable permissions not granted
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            for permission in app.permissions {
                permissionStates[permission] = true
            }
        }
    }
}

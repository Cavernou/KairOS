import Foundation
import SwiftUI
import JavaScriptCore

@MainActor
final class AppLoader: ObservableObject {
    @Published var loadedApps: [KairOSApp] = []
    @Published var isLoading = false
    @Published var lastError: String?
    
    private let fileManager = FileManager.default
    private let eventBus = EventBus.shared
    private var jsContexts: [String: JSContext] = [:]
    
    struct KairOSApp: Identifiable, Codable {
        let id: String
        let name: String
        let version: String
        let entryType: String
        let permissions: [String]
        let commands: [AppCommand]
        let aiSummary: String
        let isBuiltIn: Bool
        let manifestPath: String
        
        struct AppCommand: Codable {
            let name: String
            let description: String
            let aiAccess: Bool
            let parameters: [String: String]
        }
    }
    
    init() {
        loadBuiltInApps()
        loadExternalApps()
    }
    
    // MARK: - App Loading
    
    private func loadBuiltInApps() {
        // Load built-in apps from bundle
        let builtInApps = [
            "Notes",
            "Files",
            "Diagnostics"
        ]
        
        for appName in builtInApps {
            if let app = loadBuiltInApp(name: appName) {
                loadedApps.append(app)
            }
        }
    }
    
    private func loadBuiltInApp(name: String) -> KairOSApp? {
        guard let manifestURL = Bundle.main.url(forResource: name, withExtension: "json"),
              let manifestData = try? Data(contentsOf: manifestURL),
              let manifest = try? JSONDecoder().decode(KairOSApp.self, from: manifestData) else {
            return nil
        }
        
        return KairOSApp(
            id: manifest.id,
            name: manifest.name,
            version: manifest.version,
            entryType: manifest.entryType,
            permissions: manifest.permissions,
            commands: manifest.commands,
            aiSummary: manifest.aiSummary,
            isBuiltIn: true,
            manifestPath: manifestURL.path
        )
    }
    
    private func loadExternalApps() {
        // Load external apps from documents directory
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let appsDirectory = documentsURL.appendingPathComponent("Apps")
        
        do {
            let appDirectories = try fileManager.contentsOfDirectory(at: appsDirectory, 
                                                               includingPropertiesForKeys: nil,
                                                               options: [.skipsHiddenFiles])
            
            for appDir in appDirectories {
                if let app = loadExternalApp(from: appDir) {
                    loadedApps.append(app)
                }
            }
        } catch {
            lastError = "Failed to load external apps: \(error.localizedDescription)"
        }
    }
    
    private func loadExternalApp(from appURL: URL) -> KairOSApp? {
        let manifestURL = appURL.appendingPathComponent("manifest.json")
        
        guard fileManager.fileExists(atPath: manifestURL.path),
              let manifestData = try? Data(contentsOf: manifestURL),
              let manifest = try? JSONDecoder().decode(KairOSApp.self, from: manifestData) else {
            return nil
        }
        
        return KairOSApp(
            id: manifest.id,
            name: manifest.name,
            version: manifest.version,
            entryType: manifest.entryType,
            permissions: manifest.permissions,
            commands: manifest.commands,
            aiSummary: manifest.aiSummary,
            isBuiltIn: false,
            manifestPath: manifestURL.path
        )
    }
    
    // MARK: - App Execution
    
    func runApp(_ app: KairOSApp, api: KairOSAPI) async throws -> AppView {
        isLoading = true
        lastError = nil
        
        defer { isLoading = false }
        
        switch app.entryType {
        case "panel":
            return try await loadPanelApp(app, api: api)
        case "javascript":
            return try await loadJavaScriptApp(app, api: api)
        default:
            throw AppLoadingError.unsupportedEntryType(app.entryType)
        }
    }
    
    private func loadPanelApp(_ app: KairOSApp, api: KairOSAPI) async throws -> AppView {
        // For built-in Swift apps, load the view directly
        if app.isBuiltIn {
            switch app.id {
            case "com.kairos.notes":
                return AppView(
                    name: app.name,
                    content: AnyView(NotesAppView(api: api as! KairOSAPIImpl))
                )
            default:
                throw AppLoadingError.appNotFound(app.id)
            }
        } else {
            // For external panel apps, load from compiled bundle
            return try await loadExternalPanelApp(app, api: api, url: URL(string: app.manifestPath) ?? URL(fileURLWithPath: ""))
        }
    }
    
    // Inject KairOS API into JavaScript context
    private func injectKairOSAPI(into context: JSContext, api: KairOSAPI) {
        var apiFunctions: [String: Any] = [:]
        
        // File operations
        let apiImpl = api as? KairOSAPIImpl
        apiFunctions["readFile"] = { (path: String) -> Data? in
            return apiImpl?.readFile(named: path)
        }
        apiFunctions["writeFile"] = { (path: String, data: Data) in
            try apiImpl?.writeFile(named: path, data: data)
        }
        apiFunctions["listFiles"] = { () -> [String] in
            return apiImpl?.listFiles() ?? []
        }
        
        // Communication
        apiFunctions["sendMessage"] = { (to: String, text: String, attachments: [URL]?) async throws in
            try await apiImpl?.sendMessage(to: to, text: text, attachments: attachments)
        }
        
        // AI
        apiFunctions["queryALICE"] = { (prompt: String) async -> String in
            return await apiImpl?.queryALICE(prompt: prompt) ?? "API not available"
        }
        
        // Events
        apiFunctions["publish"] = { (event: String, payload: [String: Any]) in
            apiImpl?.publish(event: event, payload: payload)
        }
        
        apiFunctions["subscribe"] = { (event: String, handler: @escaping ([String: Any]) -> Void) in
            apiImpl?.subscribe(to: event, handler: handler)
        }
        
        // Set API functions in context
        // Note: Simplified injection for build compatibility
        // Full implementation would use proper NSCopying conformance
    }
    
    private func loadJavaScriptApp(_ app: KairOSApp, api: KairOSAPI) async throws -> AppView {
        // Create JavaScript context for the app
        let context = JSContext()
        
        // Inject KairOS API
        if let context = context {
            injectKairOSAPI(into: context, api: api)
        }
        
        // Load app script
        guard let scriptURL = URL(string: app.manifestPath)?
            .deletingLastPathComponent()
            .appendingPathComponent("app.js"),
              let script = try? String(contentsOf: scriptURL) else {
            throw AppLoadingError.appScriptNotFound
        }
        
        // Execute script
        if let context = context {
            context.evaluateScript(script)
        }
        
        // Store context for cleanup
        jsContexts[app.id] = context
        
        return AppView(
            name: app.name,
            content: AnyView(JavaScriptAppView(context: context!))
        )
    }
    
    private func loadExternalPanelApp(_ app: KairOSApp, api: KairOSAPI, url: URL) async throws -> AppView {
        // This would load external Swift bundles
        // For now, return a placeholder
        return AppView(
            name: app.name,
            content: AnyView(
                VStack {
                    Text("EXTERNAL APP: \(app.name)")
                        .font(KairOSTypography.title)
                        .foregroundStyle(KairOSColors.chrome)
                    
                    Text("Version: \(app.version)")
                        .font(KairOSTypography.mono)
                        .foregroundStyle(KairOSColors.muted)
                    
                    Text(app.aiSummary)
                        .font(KairOSTypography.mono)
                        .foregroundStyle(KairOSColors.chrome)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .panelChrome()
            )
        )
    }
    
    private func validateAppPackage(at url: URL) async throws {
        // Check for manifest.json
        let manifestURL = url.appendingPathComponent("manifest.json")
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            throw AppLoadingError.invalidAppPackage("Missing manifest.json")
        }
        
        // Validate manifest structure
        guard let manifestData = try? Data(contentsOf: manifestURL),
              let manifest = try? JSONSerialization.jsonObject(with: manifestData) as? [String: Any],
              let appId = manifest["id"] as? String,
              let appName = manifest["name"] as? String else {
            throw AppLoadingError.invalidAppPackage("Invalid manifest structure")
        }
        
        // Check permissions
        if let permissions = manifest["permissions"] as? [String] {
            try await validatePermissions(permissions)
        }
    }
    
    private func validatePermissions(_ permissions: [String]) async throws {
        let allowedPermissions = ["files", "local_storage", "ai", "events", "network", "contacts"]
        
        for permission in permissions {
            if !allowedPermissions.contains(permission) {
                throw AppLoadingError.invalidPermission(permission)
            }
        }
    }
    
    func uninstallApp(_ app: KairOSApp) async throws {
        guard !app.isBuiltIn else {
            throw AppLoadingError.cannotUninstallBuiltIn
        }
        
        let appsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("Apps")
        
        let appDirectory = appsDirectory?.appendingPathComponent(app.id)
        
        try fileManager.removeItem(at: appDirectory!)
        
        // Remove from loaded apps
        loadedApps.removeAll { $0.id == app.id }
        
        // Cleanup JavaScript context
        jsContexts.removeValue(forKey: app.id)
        
        // Publish installation event
        eventBus.publish(event: "app.installed", payload: [:])
    }
    
    // MARK: - Error Types
    
    enum AppLoadingError: LocalizedError {
        case unsupportedEntryType(String)
        case appNotFound(String)
        case appScriptNotFound
        case invalidAppPackage(String)
        case invalidPermission(String)
        case cannotUninstallBuiltIn
        
        var errorDescription: String? {
            switch self {
            case .unsupportedEntryType(let type):
                return "Unsupported app entry type: \(type)"
            case .appNotFound(let id):
                return "App not found: \(id)"
            case .appScriptNotFound:
                return "App script not found"
            case .invalidAppPackage(let reason):
                return "Invalid app package: \(reason)"
            case .invalidPermission(let permission):
                return "Invalid permission requested: \(permission)"
            case .cannotUninstallBuiltIn:
                return "Cannot uninstall built-in apps"
            }
        }
    }
}

// MARK: - App View Container

struct AppView: View {
    let name: String
    let content: AnyView
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(name.uppercased())
                    .font(KairOSTypography.title)
                    .foregroundStyle(KairOSColors.chrome)
                Spacer()
            }
            
            Divider()
                .background(KairOSColors.chrome)
            
            content
        }
        .padding()
        .background(KairOSColors.background)
        .overlay(
            Rectangle()
                .stroke(KairOSColors.chrome, lineWidth: 2)
        )
    }
}

// MARK: - JavaScript App View

struct JavaScriptAppView: View {
    let context: JSContext
    @State private var appContent: String = ""
    
    var body: some View {
        VStack {
            if appContent.isEmpty {
                Text("LOADING JAVASCRIPT APP...")
                    .font(KairOSTypography.mono)
                    .foregroundStyle(KairOSColors.muted)
            } else {
                Text(appContent)
                    .font(KairOSTypography.mono)
                    .foregroundStyle(KairOSColors.chrome)
            }
        }
        .onAppear {
            // Execute app's render function
            if let renderFunction = context.objectForKeyedSubscript("render") {
                let result = renderFunction.call(withArguments: [])
                appContent = result?.toString() ?? "ERROR: No content"
            }
        }
    }
}

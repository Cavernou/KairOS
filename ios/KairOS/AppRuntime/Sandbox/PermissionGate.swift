import Foundation
import SwiftUI

enum AppPermission: String, Codable, CaseIterable {
    case files = "files"
    case localStorage = "local_storage"
    case ai = "ai"
    case events = "events"
    
    var description: String {
        switch self {
        case .files:
            return "Access to read/write files"
        case .localStorage:
            return "Access to app-specific storage"
        case .ai:
            return "Access to ALICE AI assistant"
        case .events:
            return "Access to system event bus"
        }
    }
}

enum PermissionResult {
    case granted
    case denied
    case requiresUserPrompt
}

@MainActor
class PermissionGate: ObservableObject {
    @Published private(set) var deniedPermissions: Set<AppPermission> = []
    @Published private(set) var pendingPermissions: Set<AppPermission> = []
    
    private var grantedPermissions: Set<AppPermission> = []
    private let app: BundledAppContainer
    
    init(app: BundledAppContainer) {
        self.app = app
        // Initialize with app's declared permissions as granted
        grantedPermissions = Set(app.permissions)
    }
    
    func request(_ permission: AppPermission) async -> PermissionResult {
        // Check if app has this permission declared
        if !app.permissions.contains(permission) {
            print("⚠️ App \(app.name) requested undeclared permission: \(permission.rawValue)")
            return .denied
        }
        
        // Check if already denied
        if deniedPermissions.contains(permission) {
            return .denied
        }
        
        // Check if already granted
        if grantedPermissions.contains(permission) {
            return .granted
        }
        
        // Check if requires user prompt (high-impact permissions)
        if requiresPrompt(for: permission) {
            pendingPermissions.insert(permission)
            return .requiresUserPrompt
        }
        
        // Auto-grant for low-impact permissions
        grantedPermissions.insert(permission)
        return .granted
    }
    
    func grant(_ permission: AppPermission) {
        grantedPermissions.insert(permission)
        pendingPermissions.remove(permission)
        deniedPermissions.remove(permission)
        print("✅ Granted \(permission.rawValue) to \(app.name)")
    }
    
    func deny(_ permission: AppPermission) {
        deniedPermissions.insert(permission)
        pendingPermissions.remove(permission)
        print("❌ Denied \(permission.rawValue) to \(app.name)")
    }
    
    private func requiresPrompt(for permission: AppPermission) -> Bool {
        // High-impact permissions require user confirmation
        switch permission {
        case .files, .ai:
            return true
        case .localStorage, .events:
            return false
        }
    }
    
    func check(_ permission: AppPermission) -> Bool {
        grantedPermissions.contains(permission) && !deniedPermissions.contains(permission)
    }
    
    func checkAll(_ permissions: [AppPermission]) -> Bool {
        permissions.allSatisfy { check($0) }
    }
    
    func getGrantedPermissions() -> [AppPermission] {
        Array(grantedPermissions).sorted { $0.rawValue < $1.rawValue }
    }
    
    func getDeniedPermissions() -> [AppPermission] {
        Array(deniedPermissions).sorted { $0.rawValue < $1.rawValue }
    }
}

struct PermissionPromptView: View {
    let permission: AppPermission
    let app: BundledAppContainer
    let onGrant: () -> Void
    let onDeny: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Permission Request")
                .font(.headline)
            
            Text("\(app.name) is requesting access to:")
                .font(.subheadline)
            
            Text(permission.rawValue.uppercased())
                .font(.title2)
                .fontWeight(.bold)
            
            Text(permission.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                Button("Deny") {
                    onDeny()
                }
                .buttonStyle(.bordered)
                
                Button("Allow") {
                    onGrant()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 10)
    }
}

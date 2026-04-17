import Foundation
import Combine

enum AppLifecycleState {
    case idle
    case launching
    case active
    case suspended
    case terminated
}

@MainActor
class AppLifecycle: ObservableObject {
    @Published private(set) var currentState: AppLifecycleState = .idle
    @Published private(set) var activeApp: BundledAppContainer?
    @Published private(set) var launchTime: Date?
    @Published private(set) var suspendTime: Date?
    
    private var cancellables = Set<AnyCancellable>()
    
    func launch(_ app: BundledAppContainer) -> Bool {
        guard currentState == .idle || currentState == .terminated else {
            print("Cannot launch \(app.name): app is not idle or terminated")
            return false
        }
        
        print(" Launching \(app.name)...")
        currentState = .launching
        launchTime = .now
        
        // Simulate app launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.currentState = .active
            self?.activeApp = app
            print("Launched app: \(app.name)")
        }
        
        return true
    }
    
    func suspend() -> Bool {
        guard currentState == .active, let app = activeApp else {
            print("Cannot suspend: no active app")
            return false
        }
        
        print(" Suspending \(app.name)...")
        currentState = .suspended
        suspendTime = .now
        
        // Publish event
        EventBus.shared.publish(
            event: "app.suspended",
            payload: ["app_id": app.id, "app_name": app.name]
        )
        
        return true
    }
    
    func resume() -> Bool {
        guard currentState == .suspended, let app = activeApp else {
            print("Cannot resume: app is not suspended")
            return false
        }
        
        print("▶️ Resuming \(app.name)...")
        currentState = .active
        suspendTime = nil
        
        // Publish event
        EventBus.shared.publish(
            event: "app.resumed",
            payload: ["app_id": app.id, "app_name": app.name]
        )
        
        return true
    }
    
    func terminate() -> Bool {
        guard currentState != .terminated else {
            print("App is already terminated")
            return false
        }
        
        guard let app = activeApp else {
            print("No active app to terminate")
            return false
        }
        
        print("🛑 Terminating \(app.name)...")
        let appName = app.name
        let appId = app.id
        
        currentState = .terminated
        activeApp = nil
        launchTime = nil
        suspendTime = nil
        
        // Publish event
        EventBus.shared.publish(
            event: "app.terminated",
            payload: ["app_id": appId, "app_name": appName]
        )
        
        return true
    }
    
    func getStateDescription() -> String {
        switch currentState {
        case .idle:
            return "Idle"
        case .launching:
            return "Launching"
        case .active:
            return "Active"
        case .suspended:
            return "Suspended"
        case .terminated:
            return "Terminated"
        }
    }
    
    func getUptime() -> TimeInterval? {
        guard let launchTime = launchTime else { return nil }
        return Date().timeIntervalSince(launchTime)
    }
}

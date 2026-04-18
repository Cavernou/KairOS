import Foundation
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var hasPermission = false
    
    private init() {}
    
    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            hasPermission = granted
        } catch {
            print("Failed to request notification permission: \(error)")
            hasPermission = false
        }
    }
    
    func sendRegistrationApprovedNotification(kairNumber: String) {
        let content = UNMutableNotificationContent()
        content.title = "Registration Approved"
        content.body = "Your KairOS registration for \(kairNumber) has been approved."
        content.sound = UNNotificationSound.default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }
    
    func sendRegistrationDeniedNotification(kairNumber: String) {
        let content = UNMutableNotificationContent()
        content.title = "Registration Denied"
        content.body = "Your KairOS registration for \(kairNumber) was denied by the administrator."
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }
    
    func sendIncomingCallNotification(from kairNumber: String) {
        let content = UNMutableNotificationContent()
        content.title = "Incoming Call"
        content.body = "Call from \(kairNumber)"
        content.sound = UNNotificationSound.default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }
    
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}

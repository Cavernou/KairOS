import Combine
import Foundation
import UserNotifications

@MainActor
final class ActivationViewModel: ObservableObject {
    @Published var kairNumber: String = ""
    @Published var displayName: String = ""
    @Published var adminCode: String = ""
    @Published var activationState: String = "unconfigured"
    @Published var debugAdminCode: String?
    @Published var avatarData: Data?
    @Published var errorMessage: String?
    @Published var isActivating = false
    @Published var isPendingConfirmation = false

    private let identityManager: IdentityManager
    private let nodeClient: NodeClient
    private var pollingTask: Task<Void, Never>?

    init(identityManager: IdentityManager, nodeClient: NodeClient) {
        self.identityManager = identityManager
        self.nodeClient = nodeClient
    }

    func activate(avatarData: Data? = nil) async throws {
        isActivating = true
        defer { isActivating = false }

        // Validation
        guard !kairNumber.isEmpty else {
            errorMessage = "K-NUMBER is required"
            throw ActivationError.invalidInput
        }

        guard kairNumber.hasPrefix("K") else {
            errorMessage = "K-NUMBER must start with K"
            throw ActivationError.invalidInput
        }

        // Validate K-XXXX format (K followed by dash and 4 digits)
        let pattern = "^K-\\d{4}$"
        guard kairNumber.range(of: pattern, options: .regularExpression) != nil else {
            errorMessage = "K-NUMBER must be in format K-XXXX (4 digits)"
            throw ActivationError.invalidInput
        }

        guard !displayName.isEmpty else {
            errorMessage = "DISPLAY NAME is required"
            throw ActivationError.invalidInput
        }

        guard displayName.count >= 2 && displayName.count <= 32 else {
            errorMessage = "DISPLAY NAME must be 2-32 characters"
            throw ActivationError.invalidInput
        }

        guard !adminCode.isEmpty else {
            errorMessage = "ADMIN CODE is required"
            throw ActivationError.invalidInput
        }

        errorMessage = nil

        do {
            if identityManager.identity == nil {
                try identityManager.bootstrapIdentity(kairNumber: kairNumber)
            }

            guard let identity = identityManager.identity else {
                errorMessage = "Failed to create identity"
                throw ActivationError.identityCreationFailed
            }

            let publicKeyData = identityManager.publicKeyData() ?? Data()
            guard !publicKeyData.isEmpty else {
                errorMessage = "Failed to generate public key"
                throw ActivationError.keyGenerationFailed
            }

            let publicKey = publicKeyData.base64EncodedString()
            let result = try await nodeClient.activateDevice(
                deviceID: identity.deviceID.uuidString,
                kairNumber: identity.kairNumber,
                publicKey: publicKey,
                adminCode: adminCode,
                avatarData: avatarData ?? self.avatarData
            )
            activationState = result.state
            debugAdminCode = result.debugAdminCode

            if result.state == "active" {
                debugAdminCode = nil
                identityManager.markActivated()
            } else if result.state == "pending_confirmation" {
                isPendingConfirmation = true
                errorMessage = "Registration is pending approval from node administrator."
                startPollingForApproval()
            } else if result.state == "failed" {
                errorMessage = "Activation failed. Check your admin code and try again."
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    private func startPollingForApproval() {
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled && isPendingConfirmation {
                try? await Task.sleep(nanoseconds: UInt64(5 * 1_000_000_000)) // Poll every 5 seconds
                
                // Check if device has been activated
                if let identity = identityManager.identity, identity.status == "active" {
                    isPendingConfirmation = false
                    activationState = "active"
                    errorMessage = nil
                    NotificationManager.shared.sendRegistrationApprovedNotification(kairNumber: identity.kairNumber)
                    break
                }
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    enum ActivationError: LocalizedError {
        case invalidInput
        case identityCreationFailed
        case keyGenerationFailed

        var errorDescription: String? {
            switch self {
            case .invalidInput:
                return "Invalid input. Please check your entries."
            case .identityCreationFailed:
                return "Failed to create device identity."
            case .keyGenerationFailed:
                return "Failed to generate encryption keys."
            }
        }
    }
}

import Combine
import Foundation

@MainActor
final class ActivationViewModel: ObservableObject {
    @Published var kairNumber: String = ""
    @Published var adminCode: String = ""
    @Published var activationState: String = "unconfigured"
    @Published var debugAdminCode: String?
    @Published var avatarData: Data?

    private let identityManager: IdentityManager
    private let nodeClient: NodeClient

    init(identityManager: IdentityManager, nodeClient: NodeClient) {
        self.identityManager = identityManager
        self.nodeClient = nodeClient
    }

    func activate(avatarData: Data? = nil) async throws {
        if identityManager.identity == nil {
            try identityManager.bootstrapIdentity(kairNumber: kairNumber)
        }

        guard let identity = identityManager.identity else { return }
        let publicKeyData = identityManager.publicKeyData() ?? Data()
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
        }
    }
}

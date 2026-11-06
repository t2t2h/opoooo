// Call handle(_:) from AppDelegate.application(_:open:options:) or SceneDelegate.
import Foundation

final class WireGuardCompanionURLHandler {
    static let shared = WireGuardCompanionURLHandler()
    private init() {}

    @discardableResult
    func handle(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "aflatoonvpn" else { return false }
        switch url.host?.lowercased() {
        case "connect":
            WireGuardTunnelManager.shared.connectSavedProfile { result in
                // Surface result in the companion app UI/log; start request != handshake.
                if case .failure(let error) = result { NSLog("Aflatoon VPN connect failed: %@", error.localizedDescription) }
            }
            return true
        case "disconnect":
            WireGuardTunnelManager.shared.disconnect()
            return true
        default:
            return false
        }
    }
}

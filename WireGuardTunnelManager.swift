// Companion HOST APP code (not part of the injected dylib).
// Requires NetworkExtension entitlement and a separately signed PacketTunnel extension.
import Foundation
import NetworkExtension

final class WireGuardTunnelManager {
    static let shared = WireGuardTunnelManager()
    private let providerBundleIdentifier = "com.example.AflatoonMubdi.PacketTunnel" // CHANGE to your extension bundle ID
    private init() {}

    func connectSavedProfile(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let config = try WireGuardProfileVault.load()
            connect(wgQuickConfig: config, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    func connect(wgQuickConfig: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !wgQuickConfig.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(.failure(NSError(domain: "AflatoonWireGuard", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "WireGuard config is empty"])))
            return
        }

        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            if let error = error { completion(.failure(error)); return }
            guard let self = self else { return }
            let manager = (managers ?? []).first { item in
                (item.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == self.providerBundleIdentifier
            } ?? NETunnelProviderManager()

            let tunnelProtocol = NETunnelProviderProtocol()
            tunnelProtocol.providerBundleIdentifier = self.providerBundleIdentifier
            tunnelProtocol.serverAddress = "WireGuard"
            // For production, keep the private key in Keychain/shared secure storage;
            // do not hard-code a .conf or private key into the dylib or app binary.
            tunnelProtocol.providerConfiguration = ["wgQuickConfig": wgQuickConfig]
            manager.protocolConfiguration = tunnelProtocol
            manager.localizedDescription = "Aflatoon WireGuard"
            manager.isEnabled = true

            manager.saveToPreferences { saveError in
                if let saveError = saveError { completion(.failure(saveError)); return }
                manager.loadFromPreferences { loadError in
                    if let loadError = loadError { completion(.failure(loadError)); return }
                    do {
                        try manager.connection.startVPNTunnel()
                        completion(.success(()))
                    } catch { completion(.failure(error)) }
                }
            }
        }
    }

    func disconnect() {
        NETunnelProviderManager.loadAllFromPreferences { managers, _ in
            let manager = (managers ?? []).first { item in
                (item.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == self.providerBundleIdentifier
            }
            manager?.connection.stopVPNTunnel()
        }
    }

    func status(completion: @escaping (NEVPNStatus?) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { managers, _ in
            let manager = (managers ?? []).first { item in
                (item.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == self.providerBundleIdentifier
            }
            completion(manager?.connection.status)
        }
    }
}

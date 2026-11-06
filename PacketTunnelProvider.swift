// Separate Network Extension target. Add WireGuardKit to THIS target via Swift Package Manager.
import NetworkExtension
import WireGuardKit

final class PacketTunnelProvider: NEPacketTunnelProvider {
    private var adapter: WireGuardAdapter?

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        guard let tunnelProtocol = protocolConfiguration as? NETunnelProviderProtocol,
              let providerConfiguration = tunnelProtocol.providerConfiguration,
              let wgQuickConfig = providerConfiguration["wgQuickConfig"] as? String,
              !wgQuickConfig.isEmpty else {
            completionHandler(NSError(domain: "AflatoonWireGuard", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Missing WireGuard configuration"])))
            return
        }

        do {
            let tunnelConfiguration = try TunnelConfiguration(
                fromWgQuickConfig: wgQuickConfig,
                called: "Aflatoon WireGuard"
            )
            let wireGuardAdapter = WireGuardAdapter(with: self)
            adapter = wireGuardAdapter
            wireGuardAdapter.start(tunnelConfiguration: tunnelConfiguration) { error in
                completionHandler(error)
            }
        } catch {
            completionHandler(error)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        guard let adapter = adapter else { completionHandler(); return }
        adapter.stop { _ in completionHandler() }
    }
}

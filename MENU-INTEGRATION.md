# Net menu profile import

The `UI.m` Net tab now adds a document-picker/share-sheet workflow. It intentionally asks the user to select the `.conf` file from Files instead of embedding a WireGuard private key into the tweak's compiled dylib.

1. Copy `Profiles/MARCO-FREEVPN.conf` into the iPhone Files app (On My iPhone or iCloud Drive).
2. Open the target app and the AflatoonMubdi menu → `net`.
3. Tap `IMPORT MARCO .CONF → WIREGUARD`.
4. Select the `.conf` file, then choose WireGuard in the share sheet.
5. In WireGuard, review the imported profile and tap its toggle to connect.

This imports the profile; it does not start the tunnel from inside the tweak. A true in-menu toggle requires a signed host app with a Packet Tunnel extension and an explicit IPC bridge.

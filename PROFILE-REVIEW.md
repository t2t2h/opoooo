# MARCO profile review for V2

The private key supplied in the conversation was exposed. It has been removed from this project and replaced with `REPLACE_WITH_NEW_PRIVATE_KEY`. Obtain a newly generated client profile/key from the VPN provider before importing it. Do not reuse the exposed key.

The supplied MTU value was 65535, which is unsuitable for many real network paths and can cause fragmentation/black-hole problems. The packaged template uses 1420 as a common WireGuard starting point; the provider's recommended MTU takes precedence.

The profile's AllowedIPs contains selected networks, not `0.0.0.0/0` and `::/0`, so it is split routing, not a guaranteed full-device tunnel. Do not change AllowedIPs without confirming the provider's intended routes. The unusual Interface Address list should also be validated by the provider.

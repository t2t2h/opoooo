# Create your own WireGuard server

There is no public VPN server or credential bundled with AflatoonMubdi. WireGuard software is free/open source; a reachable server still needs to run somewhere. You can use a Linux computer you own with a public IPv4 address, or a VPS. A cloud free tier is provider-dependent and is not guaranteed to remain free.

## Requirements

- Ubuntu 22.04/24.04 or a current Debian server.
- Public IPv4 address or DNS name, and inbound UDP access (default 51820).
- Root/sudo access.
- For a home server: router UDP port-forwarding to the Linux machine. If your ISP uses CGNAT, inbound hosting normally will not work without a public IP or a relay/VPS.

## Install

Copy `setup-wireguard.sh` to the Linux server, then run:

```sh
sudo bash setup-wireguard.sh
```

Enter the server's public IPv4/DNS name and UDP port. The script installs WireGuard, creates one server peer and one iPhone client profile, enables IPv4 forwarding, configures NAT, and starts `wg0`.

The client profile is written to:

```text
/root/wireguard-client/aflatoon-client.conf
```

Transfer that file to your iPhone over a secure channel and import it in the official WireGuard app. Do not email it publicly, commit it to Git, or include it in the tweak ZIP. It contains a private key.

## Verify

```sh
sudo wg show
sudo systemctl status wg-quick@wg0
```

After the iPhone connects, `wg show` should display a recent `latest handshake` and increasing transfer counters. Also verify the public IPv4 from the iPhone using the IP-check button in AflatoonMubdi.

## Network caveats

- Open UDP `51820` (or your chosen port) in both the server firewall and cloud-provider firewall/security group.
- The provided profile routes IPv4 (`0.0.0.0/0`) only. It does not configure IPv6; IPv6 may bypass this tunnel. Do not describe this profile as full dual-stack protection.
- This basic script creates one client. For additional devices, generate a distinct key pair and peer for each device; never reuse the iPhone private key.
- A free software stack does not mean free hosting or free internet bandwidth.

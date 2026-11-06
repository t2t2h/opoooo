#!/usr/bin/env bash
# Self-hosted WireGuard server bootstrap for Ubuntu/Debian.
# Run as root on a Linux server with a public IPv4 address.
set -euo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "Run as root: sudo bash setup-wireguard.sh" >&2
  exit 1
fi
if ! command -v apt-get >/dev/null 2>&1; then
  echo "This script supports Ubuntu/Debian (apt)." >&2
  exit 1
fi

read -r -p "Public IPv4 or DNS name of this server: " ENDPOINT
if [[ -z "$ENDPOINT" || "$ENDPOINT" =~ [[:space:]] ]]; then
  echo "A valid public IP or DNS name is required." >&2
  exit 1
fi
read -r -p "WireGuard UDP port [51820]: " PORT
PORT=${PORT:-51820}
if ! [[ "$PORT" =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )); then
  echo "Invalid UDP port." >&2
  exit 1
fi

WAN_IF=$(ip -4 route list default 2>/dev/null | awk 'NR==1 {print $5}')
if [[ -z "$WAN_IF" ]]; then
  echo "Could not detect the default network interface." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y wireguard wireguard-tools iptables

umask 077
install -d -m 700 /etc/wireguard
SERVER_PRIV=$(wg genkey)
SERVER_PUB=$(printf '%s' "$SERVER_PRIV" | wg pubkey)
CLIENT_PRIV=$(wg genkey)
CLIENT_PUB=$(printf '%s' "$CLIENT_PRIV" | wg pubkey)

SYSCTL_FILE=/etc/sysctl.d/99-wireguard-forward.conf
cat > "$SYSCTL_FILE" <<SYSCTL
net.ipv4.ip_forward=1
SYSCTL
sysctl --system >/dev/null

cat > /etc/wireguard/wg0.conf <<WG
[Interface]
Address = 10.66.66.1/24
ListenPort = ${PORT}
PrivateKey = ${SERVER_PRIV}

PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ${WAN_IF} -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ${WAN_IF} -j MASQUERADE

[Peer]
PublicKey = ${CLIENT_PUB}
AllowedIPs = 10.66.66.2/32
WG
chmod 600 /etc/wireguard/wg0.conf

install -d -m 700 /root/wireguard-client
cat > /root/wireguard-client/aflatoon-client.conf <<CLIENT
[Interface]
PrivateKey = ${CLIENT_PRIV}
Address = 10.66.66.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = ${SERVER_PUB}
Endpoint = ${ENDPOINT}:${PORT}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
CLIENT
chmod 600 /root/wireguard-client/aflatoon-client.conf

if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
  ufw allow "${PORT}/udp"
fi
systemctl enable --now wg-quick@wg0

cat <<DONE

WireGuard server configured.
- Interface: wg0
- UDP port: ${PORT}
- WAN interface: ${WAN_IF}
- Client config: /root/wireguard-client/aflatoon-client.conf

NEXT STEPS:
1. Allow UDP ${PORT} in your cloud firewall/security group as well as the host firewall.
2. If this is a home server, forward UDP ${PORT} on your router to this machine.
3. Transfer the client config securely to your iPhone, then import it in the official WireGuard app.
4. Keep the client .conf private: it contains the client's private key.
5. Check the handshake with: wg show

This generated profile tunnels IPv4 only. IPv6 is not routed by this basic setup and may bypass the tunnel.
DONE

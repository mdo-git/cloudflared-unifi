# Cloudflared on UniFi OS

Self-healing Cloudflare Tunnel installation for:

- UniFi Dream Router (UDR)
- UniFi Dream Machine Pro (UDM Pro)

Features:

- Survives UniFi firmware updates
- Recreates Cloudflare apt repository
- Recreates Cloudflare GPG key
- Automatically upgrades cloudflared
- Rebuilds and restarts systemd service
- Token-based tunnel authentication
- Stores persistent binaries under /data/cloudflared

# cloudflared on UniFi gateways

This repository documents a persistent `cloudflared` installation on UniFi gateways where local changes under the normal root filesystem may not survive firmware updates. The tested layout stores the executable, token, scripts and logs under `/data/cloudflared`.

## Files

- `repair.sh` — manual recovery/reinstallation helper. It reads `/data/cloudflared/config.env`, checks the Cloudflare repository/key, ensures the binary and token exist, writes the tunnel service, and starts it.
- `update.sh` — checks the Cloudflare apt package and updates the persistent binary only when the version differs; restarts the tunnel only after a binary update.
- `systemd/cloudflared.service` — runs the tunnel using the persistent binary and token file.
- `systemd/cloudflared-update.service` and `.timer` — run update checks 3 minutes after boot and then every 7 days.
- `config.env.example` — safe template for the local `config.env`.

## Security

**Never commit the real `/data/cloudflared/token` file.** It contains the tunnel credential. Do not commit runtime logs or the compiled `cloudflared` executable either. Keep the real `config.env` on the router; copy `config.env.example` to `/data/cloudflared/config.env` only if creating a fresh installation and verify values before use.

## Install/update setup

These instructions assume the scripts have been copied to `/data/cloudflared` and systemd is available. Run commands as root.

```sh
mkdir -p /data/cloudflared
chmod 755 /data/cloudflared/repair.sh /data/cloudflared/update.sh
cp systemd/cloudflared.service /etc/systemd/system/
cp systemd/cloudflared-update.service /etc/systemd/system/
cp systemd/cloudflared-update.timer /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now cloudflared.service
systemctl enable --now cloudflared-update.timer
```

Do not overwrite an existing live `config.env` or token as part of an update. Review the files and local paths first.

## Verify

```sh
systemctl status cloudflared.service --no-pager
systemctl status cloudflared-update.timer --no-pager
systemctl list-timers cloudflared-update.timer
/data/cloudflared/cloudflared --version
 tail -n 50 /data/cloudflared/update.log
```

For recovery steps and common failure checks, see [`RECOVERY.MD`](RECOVERY.MD). For routine operations, see [`OPERATIONS.md`](OPERATIONS.md).

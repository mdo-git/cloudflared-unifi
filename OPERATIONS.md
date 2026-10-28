# Routine operations

Run commands as root on the relevant UniFi gateway.

## Check health

```sh
systemctl is-active cloudflared.service
systemctl status cloudflared.service --no-pager
systemctl list-timers cloudflared-update.timer
```

## View logs

```sh
tail -n 60 /data/cloudflared/update.log
tail -n 60 /data/cloudflared/repair.log
journalctl -u cloudflared.service -n 60 --no-pager
```

## Run an update check now

```sh
systemctl start cloudflared-update.service
systemctl status cloudflared-update.service --no-pager
tail -n 100 /data/cloudflared/update.log
```

## Run repair manually

```sh
bash /data/cloudflared/repair.sh
```

Use repair only when needed. The weekly update timer is separate from repair. No daily repair job is required for this setup.

## Enable or disable scheduled update checks

```sh
systemctl enable --now cloudflared-update.timer
systemctl disable --now cloudflared-update.timer
```

Disabling the timer does not stop the tunnel service.

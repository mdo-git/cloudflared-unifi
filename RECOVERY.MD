# Recovery guide

Use this guide when the Cloudflare tunnel is offline. Avoid changing the tunnel token or hostname unless Cloudflare itself indicates the tunnel credentials/configuration need replacing.

## 1. Check service and timer

```sh
systemctl status cloudflared.service --no-pager
journalctl -u cloudflared.service -n 80 --no-pager
systemctl status cloudflared-update.timer --no-pager
systemctl status cloudflared-update.service --no-pager
```

## 2. Check persistent files

```sh
ls -l /data/cloudflared/
/data/cloudflared/cloudflared --version
```

The directory should include `cloudflared`, `token`, `config.env`, `repair.sh`, and `update.sh`. Logs are normally `repair.log` and `update.log`. Do not display or share the contents of `token`.

## 3. Run manual repair

Run only if the persistent binary is missing/invalid or the service needs repair:

```sh
bash /data/cloudflared/repair.sh
systemctl status cloudflared.service --no-pager
tail -n 80 /data/cloudflared/repair.log
```

`repair.sh` can install the package and rewrite the service. It expects `/data/cloudflared/config.env` and a non-empty `/data/cloudflared/token` to exist. It does not create or retrieve a replacement tunnel token.

## 4. Check update log

```sh
tail -n 100 /data/cloudflared/update.log
systemctl status cloudflared-update.service --no-pager
```

The update timer runs around three minutes after boot and then every seven days. If no version change is available, it should not restart the tunnel. If the package update fails, inspect network/DNS/repository errors in the log before retrying.

## 5. Manual restart

```sh
systemctl restart cloudflared.service
systemctl is-active cloudflared.service
journalctl -u cloudflared.service -n 50 --no-pager
```

If it remains inactive, check the token file exists and is non-empty without printing its contents:

```sh
test -s /data/cloudflared/token && echo "token file present" || echo "token file missing/empty"
```

Do not publish tokens, logs containing sensitive information, or router configuration exports in a public issue.

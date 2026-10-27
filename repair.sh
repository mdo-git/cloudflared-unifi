#!/bin/bash

LOGFILE="/data/cloudflared/repair.log"

exec >>"$LOGFILE" 2>&1

echo
echo "========== $(date) =========="
echo "repair.sh starting"
echo "PID $$"
echo "repair.sh executed on $(hostname)"

set -e

CONFIG="/data/cloudflared/config.env"

if [ ! -f "$CONFIG" ]; then
    echo "[ERR ] Missing config.env"
    exit 1
fi

source "$CONFIG"

log_ok() {
    echo "[ OK ] $1"
}

log_fix() {
    echo "[FIX] $1"
}

log_err() {
    echo "[ERR ] $1"
}

ensure_keyring() {
    if [ -f "$CF_KEYRING" ]; then
        log_ok "GPG key found"
        return
    fi

    log_fix "Installing GPG key"

    mkdir -p "$(dirname "$CF_KEYRING")"

    curl -fsSL "$CF_GPG_URL" \
        | gpg --dearmor \
        -o "$CF_KEYRING"

    chmod 644 "$CF_KEYRING"
}

ensure_repository() {

    if grep -q "pkg.cloudflare.com/cloudflared" "$CF_REPO_FILE" 2>/dev/null; then
        log_ok "Repository found"
        return
    fi

    log_fix "Creating repository"

    echo "$CF_REPO" > "$CF_REPO_FILE"
}

install_cloudflared() {

    log_fix "Installing cloudflared package"

    for attempt in 1 2 3 4 5; do

        echo "Attempt ${attempt}/5..."

        if apt-get update && apt-get install -y cloudflared; then

            if [ ! -x /usr/bin/cloudflared ]; then
                log_err "Package installed but /usr/bin/cloudflared not found"
                exit 1
            fi

            systemctl stop "$CF_SERVICE" >/dev/null 2>&1 || true

            cp /usr/bin/cloudflared "$CF_BINARY"
            chmod 755 "$CF_BINARY"
            VERSION=$("$CF_BINARY" --version | head -1)
            log_ok "Installed $VERSION"

            "$CF_BINARY" --version >/dev/null

            log_ok "Binary copied to $CF_BINARY"
            return
        fi

        echo "Network not ready - waiting 15 seconds..."
        sleep 15
    done

    log_err "Failed to install cloudflared"
    exit 1
}

ensure_binary() {

    if [ -x "$CF_BINARY" ] && "$CF_BINARY" --version >/dev/null 2>&1; then
        log_ok "Binary found"
        return
    fi

    install_cloudflared
}

ensure_token() {

    if [ -s "$CF_TOKEN_FILE" ]; then
        log_ok "Tunnel token found"
        return
    fi

    log_err "Missing tunnel token: $CF_TOKEN_FILE"
    exit 1
}

ensure_service() {

    log_fix "Writing service file"

    cat >/etc/systemd/system/$CF_SERVICE <<EOF
[Unit]
Description=cloudflared
After=network-online.target
Wants=network-online.target

[Service]
TimeoutStartSec=15
Type=notify
ExecStart=$CF_BINARY --no-autoupdate tunnel run --token-file $CF_TOKEN_FILE
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

    log_ok "Service written"
}

reload_systemd() {
    log_fix "Reloading systemd"
    systemctl daemon-reload
}

start_service() {

    log_fix "Starting service"

    systemctl enable "$CF_SERVICE" >/dev/null 2>&1 || true

    for attempt in 1 2; do

        systemctl restart "$CF_SERVICE"

        sleep 5

        if systemctl is-active --quiet "$CF_SERVICE"; then
            log_ok "Service started"
            return
        fi

        echo "Retrying..."
    done

    log_err "Service failed to start"

    systemctl status "$CF_SERVICE" --no-pager || true

    exit 1
}

main() {

    ensure_keyring

    ensure_repository

    install_cloudflared

    ensure_token

    ensure_service

    reload_systemd

    start_service

    log_ok "Repair completed"
}

main

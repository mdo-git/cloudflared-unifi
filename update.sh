#!/bin/bash
set -Ee

BASE="/data/cloudflared"
BINARY="$BASE/cloudflared"
LOG="$BASE/update.log"
SERVICE="cloudflared.service"

mkdir -p "$BASE"
exec >>"$LOG" 2>&1

echo
echo "========== $(date) =========="
echo "Cloudflare update check on $(hostname)"

# Confirm the existing installation is usable.
if [ ! -x "$BINARY" ] || ! "$BINARY" --version >/dev/null 2>&1; then
    echo "[ERR] Persistent cloudflared binary missing or invalid."
    echo "[ERR] Run repair.sh manually to recover the installation."
    exit 1
fi

OLD_VERSION=$("$BINARY" --version | awk '{print $3}')
echo "[INFO] Persistent version: $OLD_VERSION"

# Refresh package information and install any available update.
apt-get update
apt-get install -y cloudflared

if [ ! -x /usr/bin/cloudflared ]; then
    echo "[ERR] Packaged cloudflared binary missing."
    exit 1
fi

PACKAGE_VERSION=$(dpkg-query -W -f='${Version}' cloudflared)
PACKAGE_BINARY_VERSION=$(/usr/bin/cloudflared --version | awk '{print $3}')

echo "[INFO] Installed package: $PACKAGE_VERSION"
echo "[INFO] Package binary:    $PACKAGE_BINARY_VERSION"

if [ "$PACKAGE_VERSION" != "$PACKAGE_BINARY_VERSION" ]; then
    echo "[ERR] Package and binary versions do not agree."
    exit 1
fi

# Replace the persistent binary only when an update is needed.
if [ "$OLD_VERSION" != "$PACKAGE_BINARY_VERSION" ]; then
    echo "[FIX] Updating persistent binary: $OLD_VERSION -> $PACKAGE_BINARY_VERSION"

    cp /usr/bin/cloudflared "$BINARY.new"
    chmod 755 "$BINARY.new"

    if ! "$BINARY.new" --version >/dev/null 2>&1; then
        rm -f "$BINARY.new"
        echo "[ERR] New binary failed its version check."
        exit 1
    fi

    mv -f "$BINARY.new" "$BINARY"

    echo "[FIX] Restarting tunnel with updated binary."
    systemctl restart "$SERVICE"
    sleep 3

    if ! systemctl is-active --quiet "$SERVICE"; then
        echo "[ERR] Tunnel service failed to become active."
        systemctl status "$SERVICE" --no-pager || true
        exit 1
    fi

    echo "[FIX] Tunnel restarted successfully."
else
    echo "[ OK] Persistent binary is already up to date."
    echo "[ OK] No tunnel restart required."
fi

echo "[ OK] Update check completed."

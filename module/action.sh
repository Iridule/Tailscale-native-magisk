#!/system/bin/sh

MODDIR=${0%/*}
. "$MODDIR/common.sh"

TAILSCALE="$MODDIR/bin/tailscale"

if [ "$1" != "binary-update" ]; then
    if ! pm path io.github.a13e300.ksuwebui >/dev/null 2>&1; then
        echo "KsuWebUIStandalone is required to open this module's dashboard."
        echo "Install it, then tap Action again."
        echo "https://github.com/KOWX712/KsuWebUIStandalone/releases"
        exit 1
    fi
    echo "Opening Native Tailscale dashboard..."
    am start \
        -n io.github.a13e300.ksuwebui/.WebUIActivity \
        -d ksuwebui://webui/native_tailscale \
        --es id native_tailscale \
        --es name "Native Tailscale TUN" >/dev/null 2>&1 || {
            echo "ERROR: KsuWebUIStandalone could not open the dashboard."
            exit 1
        }
    exit 0
fi

if ! pid_is_ours; then
    echo "Native tailscaled is not running; starting it..."
    if official_tailscale_vpn_active; then
        echo "ERROR: Disconnect the official Tailscale Android app first."
        exit 1
    fi
    if ! start_daemon; then
        echo "ERROR: tailscaled did not start. Check $LOGFILE"
        exit 1
    fi
fi

STATUS_JSON="$($TAILSCALE --socket="$SOCKET" status --json 2>/dev/null)"
BACKEND_STATE="$(printf '%s\n' "$STATUS_JSON" |
    sed -n 's/.*"BackendState"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' |
    head -n 1)"

case "$BACKEND_STATE" in
    NeedsLogin|NoState)
        echo "ERROR: Sign in from the dashboard before updating Tailscale binaries."
        exit 1
        ;;
    NeedsMachineAuth)
        echo "This device is signed in but is waiting for an administrator to approve it."
        echo "Approve it in the Tailscale admin console before updating binaries."
        exit 1
        ;;
    "")
        echo "ERROR: Could not read tailscaled status. Check $LOGFILE"
        exit 1
        ;;
esac

REPO_RAW=https://raw.githubusercontent.com/android-kxxt/external_tailscale_prebuilt/main
TMP="$BASE/update.$$"
REMOTE_COMMIT_FILE="$TMP/commit"
POST_COMMIT_FILE="$TMP/commit-after"
INSTALLED_COMMIT_FILE="$MODDIR/upstream_commit"

cleanup() {
    rm -rf "$TMP"
}
trap cleanup EXIT INT TERM

mkdir -p "$TMP"

valid_commit_marker() {
    MARKER="$1"
    [ "${#MARKER}" -eq 40 ] || return 1
    case "$MARKER" in
        *[!0-9a-f]*)
            return 1
            ;;
    esac
}

echo "Native Tailscale updater"
echo

if ! verify_binary_hashes; then
    echo "ERROR: Installed binaries do not match their recorded SHA-256 hashes."
    echo "Reinstall the module or review the files before attempting an update."
    exit 1
fi

CURRENT_VERSION="$("$MODDIR/bin/tailscaled" --version 2>/dev/null | head -n 1)"
[ -n "$CURRENT_VERSION" ] || CURRENT_VERSION="unknown"
echo "Installed Tailscale: $CURRENT_VERSION"

if ! download_file "$REPO_RAW/commit" "$REMOTE_COMMIT_FILE"; then
    echo "ERROR: Could not download the upstream commit marker."
    exit 1
fi

REMOTE_COMMIT="$(tr -d '\r\n ' < "$REMOTE_COMMIT_FILE")"
if ! valid_commit_marker "$REMOTE_COMMIT"; then
    echo "ERROR: Invalid upstream commit marker."
    exit 1
fi

INSTALLED_COMMIT="$(cat "$INSTALLED_COMMIT_FILE" 2>/dev/null | tr -d '\r\n ')"
echo "Installed source commit: ${INSTALLED_COMMIT:-unknown}"
echo "Upstream source commit:  $REMOTE_COMMIT"

if [ "$REMOTE_COMMIT" = "$INSTALLED_COMMIT" ]; then
    echo
    echo "Already current."
    "$MODDIR/bin/tailscale" --socket="$SOCKET" status 2>/dev/null || true
    exit 0
fi

echo
echo "Downloading new ARM64 binaries..."

if ! download_file "$REPO_RAW/arm64/tailscale?commit=$REMOTE_COMMIT" "$TMP/tailscale"; then
    echo "ERROR: tailscale download failed."
    exit 1
fi

if ! download_file "$REPO_RAW/arm64/tailscaled?commit=$REMOTE_COMMIT" "$TMP/tailscaled"; then
    echo "ERROR: tailscaled download failed."
    exit 1
fi

if ! download_file "$REPO_RAW/commit" "$POST_COMMIT_FILE"; then
    echo "ERROR: Could not recheck the upstream commit marker."
    exit 1
fi

POST_COMMIT="$(tr -d '\r\n ' < "$POST_COMMIT_FILE")"
if ! valid_commit_marker "$POST_COMMIT"; then
    echo "ERROR: Invalid upstream commit marker after download."
    exit 1
fi

if [ "$POST_COMMIT" != "$REMOTE_COMMIT" ]; then
    echo "ERROR: Upstream changed during download. Run Update Tailscale again."
    exit 1
fi

chmod 0755 "$TMP/tailscale" "$TMP/tailscaled"

if ! is_elf "$TMP/tailscale" || ! is_elf "$TMP/tailscaled"; then
    echo "ERROR: A downloaded file is not an ELF executable."
    exit 1
fi

NEW_VERSION="$("$TMP/tailscaled" --version 2>/dev/null | head -n 1)"
if [ -z "$NEW_VERSION" ]; then
    echo "ERROR: The downloaded daemon did not execute."
    exit 1
fi

echo "Downloaded Tailscale: $NEW_VERSION"
sha256sum "$TMP/tailscale" "$TMP/tailscaled" |
    tee "$BASE/last-update.sha256"

WAS_RUNNING=0
pid_is_ours && WAS_RUNNING=1

cp -fp "$MODDIR/bin/tailscale" "$MODDIR/bin/tailscale.bak" 2>/dev/null || true
cp -fp "$MODDIR/bin/tailscaled" "$MODDIR/bin/tailscaled.bak" 2>/dev/null || true
cp -fp "$MODDIR/binary-sha256" "$MODDIR/binary-sha256.bak" 2>/dev/null || true

stop_daemon

cp -f "$TMP/tailscale" "$MODDIR/bin/tailscale"
cp -f "$TMP/tailscaled" "$MODDIR/bin/tailscaled"
chmod 0755 "$MODDIR/bin/tailscale" "$MODDIR/bin/tailscaled"
if ! record_binary_hashes; then
    echo "ERROR: Could not record the downloaded binary hashes."
    [ -f "$MODDIR/bin/tailscale.bak" ] &&
        cp -f "$MODDIR/bin/tailscale.bak" "$MODDIR/bin/tailscale"
    [ -f "$MODDIR/bin/tailscaled.bak" ] &&
        cp -f "$MODDIR/bin/tailscaled.bak" "$MODDIR/bin/tailscaled"
    [ -f "$MODDIR/binary-sha256.bak" ] &&
        cp -f "$MODDIR/binary-sha256.bak" "$MODDIR/binary-sha256"
    [ "$WAS_RUNNING" -eq 1 ] && start_daemon || true
    exit 1
fi

if official_tailscale_vpn_active; then
    printf '%s\n' "$REMOTE_COMMIT" > "$INSTALLED_COMMIT_FILE"
    echo
    echo "Updated successfully."
    echo "Native daemon was not started because the official Android Tailscale VPN is active."
    exit 0
fi

if start_daemon; then
    printf '%s\n' "$REMOTE_COMMIT" > "$INSTALLED_COMMIT_FILE"
    echo
    echo "Update succeeded and tailscaled restarted."
    "$MODDIR/bin/tailscale" --socket="$SOCKET" status 2>/dev/null || true
    exit 0
fi

echo
echo "New daemon failed to start; rolling back."

stop_daemon
[ -f "$MODDIR/bin/tailscale.bak" ] &&
    cp -f "$MODDIR/bin/tailscale.bak" "$MODDIR/bin/tailscale"
[ -f "$MODDIR/bin/tailscaled.bak" ] &&
    cp -f "$MODDIR/bin/tailscaled.bak" "$MODDIR/bin/tailscaled"
[ -f "$MODDIR/binary-sha256.bak" ] &&
    cp -f "$MODDIR/binary-sha256.bak" "$MODDIR/binary-sha256"
chmod 0755 "$MODDIR/bin/tailscale" "$MODDIR/bin/tailscaled"

if [ "$WAS_RUNNING" -eq 1 ]; then
    start_daemon || true
fi

echo "Rollback complete. Check $LOGFILE"
exit 1

#!/system/bin/sh

MODDIR="${MODDIR:-${0%/*}}"
BASE=/data/adb/tailscale-native
SOCKET="$BASE/tailscaled.sock"
STATE="$BASE/tailscaled.state"
PIDFILE="$BASE/tailscaled.pid"
LOGFILE="$BASE/tailscaled.log"

mkdir -p "$BASE"
chmod 0700 "$BASE"
umask 077

managed_daemon_pid() {
    for CANDIDATE in $(pidof tailscaled 2>/dev/null); do
        [ -r "/proc/$CANDIDATE/cmdline" ] || continue
        CMD="$(tr '\000' ' ' < "/proc/$CANDIDATE/cmdline" 2>/dev/null)"
        case "$CMD" in
            *"--state=$STATE"*"--socket=$SOCKET"*"--tun=tailscale0"*)
                echo "$CANDIDATE"
                return 0
                ;;
        esac
    done
    return 1
}

pid_is_ours() {
    PID="$(cat "$PIDFILE" 2>/dev/null)"
    if [ -n "$PID" ] && [ -r "/proc/$PID/cmdline" ]; then
        CMD="$(tr '\000' ' ' < "/proc/$PID/cmdline" 2>/dev/null)"
        case "$CMD" in
            *"--state=$STATE"*"--socket=$SOCKET"*"--tun=tailscale0"*)
                return 0
                ;;
        esac
    fi

    PID="$(managed_daemon_pid)" || return 1
    echo "$PID" > "$PIDFILE"
    return 0
}

official_tailscale_vpn_active() {
    dumpsys connectivity 2>/dev/null |
        grep -Fq "VPN:com.tailscale.ipn"
}

legacy_pid_list() {
    for P in $(pidof tailscaled 2>/dev/null); do
        [ -r "/proc/$P/cmdline" ] || continue
        CMD="$(tr '\000' ' ' < "/proc/$P/cmdline" 2>/dev/null)"
        case "$CMD" in
            /data/adb/tailscale-native/bin/tailscaled*)
                echo "$P"
                ;;
        esac
    done
}

stop_legacy_daemon() {
    LEGACY_PIDS="$(legacy_pid_list)"
    [ -n "$LEGACY_PIDS" ] || return 0

    for P in $LEGACY_PIDS; do
        kill "$P" 2>/dev/null
    done

    I=0
    while [ "$I" -lt 15 ]; do
        REMAINING="$(legacy_pid_list)"
        [ -z "$REMAINING" ] && break
        sleep 1
        I=$((I + 1))
    done

    for P in $(legacy_pid_list); do
        kill -9 "$P" 2>/dev/null
    done

    rm -f "$PIDFILE" "$SOCKET"
}

stop_daemon() {
    if ! pid_is_ours; then
        rm -f "$PIDFILE" "$SOCKET"
        return 0
    fi

    PID="$(cat "$PIDFILE")"
    kill "$PID" 2>/dev/null

    I=0
    while [ "$I" -lt 15 ] && pid_is_ours; do
        sleep 1
        I=$((I + 1))
    done

    if pid_is_ours; then
        kill -9 "$PID" 2>/dev/null
        sleep 1
    fi

    rm -f "$PIDFILE" "$SOCKET"
}

start_daemon() {
    if pid_is_ours; then
        return 0
    fi

    if pidof tailscaled >/dev/null 2>&1 || ip link show tailscale0 >/dev/null 2>&1; then
        echo "$(date): refusing to start: another tailscaled or tailscale0 already exists" \
            >> "$LOGFILE"
        return 1
    fi

    [ -x "$MODDIR/bin/tailscaled" ] || return 1
    rm -f "$PIDFILE" "$SOCKET"

    "$MODDIR/bin/tailscaled" \
        --state="$STATE" \
        --statedir="$BASE" \
        --socket="$SOCKET" \
        --tun=tailscale0 \
        --verbose=1 \
        >>"$LOGFILE" 2>&1 &

    PID=$!
    echo "$PID" > "$PIDFILE"

    I=0
    while [ "$I" -lt 20 ]; do
        if [ -S "$SOCKET" ] && pid_is_ours; then
            return 0
        fi
        sleep 1
        I=$((I + 1))
    done

    return 1
}

download_file() {
    URL="$1"
    OUT="$2"

    rm -f "$OUT"

    if command -v wget >/dev/null 2>&1; then
        wget -q -T 45 -O "$OUT" "$URL" && [ -s "$OUT" ] && return 0
    fi

    TERMUX_CURL=/data/data/com.termux/files/usr/bin/curl
    if [ -x "$TERMUX_CURL" ]; then
        "$TERMUX_CURL" -fsSL --connect-timeout 20 --max-time 180 \
            -o "$OUT" "$URL" && [ -s "$OUT" ] && return 0
    fi

    return 1
}

is_elf() {
    FILE="$1"
    MAGIC="$(
        dd if="$FILE" bs=4 count=1 2>/dev/null |
        od -An -tx1 2>/dev/null |
        tr -d ' \n'
    )"
    [ "$MAGIC" = "7f454c46" ]
}

record_binary_hashes() {
    (
        cd "$MODDIR" || exit 1
        sha256sum bin/tailscale bin/tailscaled > binary-sha256
        chmod 0600 binary-sha256
    )
}

verify_binary_hashes() {
    [ -s "$MODDIR/binary-sha256" ] || return 1
    (cd "$MODDIR" && sha256sum -c binary-sha256 >/dev/null 2>&1)
}

android_device_hostname() {
    DEVICE_NAME="$(settings get global device_name 2>/dev/null)"
    [ -n "$DEVICE_NAME" ] && [ "$DEVICE_NAME" != null ] ||
        DEVICE_NAME="$(settings get secure bluetooth_name 2>/dev/null)"
    [ -n "$DEVICE_NAME" ] && [ "$DEVICE_NAME" != null ] ||
        DEVICE_NAME="$(getprop ro.product.marketname 2>/dev/null)"
    [ -n "$DEVICE_NAME" ] ||
        DEVICE_NAME="$(getprop ro.product.model 2>/dev/null)"
    [ -n "$DEVICE_NAME" ] || DEVICE_NAME=android-device

    printf '%s\n' "$DEVICE_NAME" |
        tr '[:upper:]' '[:lower:]' |
        sed 's/[^a-z0-9.-]/-/g; s/--*/-/g; s/^[.-]*//; s/[.-]*$//' |
        cut -c1-63
}

ensure_device_hostname() {
    [ -x "$MODDIR/bin/tailscale" ] || return 1
    PREFS_JSON="$("$MODDIR/bin/tailscale" --socket="$SOCKET" debug prefs 2>/dev/null)"
    CONFIGURED_HOSTNAME="$(printf '%s\n' "$PREFS_JSON" |
        sed -n 's/.*"Hostname"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' |
        head -n 1)"
    [ -z "$CONFIGURED_HOSTNAME" ] || return 0
    DEVICE_HOSTNAME="$(android_device_hostname)"
    [ -n "$DEVICE_HOSTNAME" ] || return 1
    "$MODDIR/bin/tailscale" --socket="$SOCKET" set \
        --hostname="$DEVICE_HOSTNAME" >/dev/null 2>&1
}

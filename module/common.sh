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

pid_is_ours() {
    [ -r "$PIDFILE" ] || return 1
    PID="$(cat "$PIDFILE" 2>/dev/null)"
    [ -n "$PID" ] || return 1
    [ -r "/proc/$PID/cmdline" ] || return 1
    tr '\000' ' ' < "/proc/$PID/cmdline" 2>/dev/null |
        grep -Fq "$MODDIR/bin/tailscaled"
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

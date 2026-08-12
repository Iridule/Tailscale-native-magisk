#!/system/bin/sh

MODDIR=${0%/*}
. "$MODDIR/common.sh"

TAILSCALE="$MODDIR/bin/tailscale"

field() {
    printf '%s=%s\n' "$1" "$2"
}

json_value() {
    printf '%s\n' "$1" |
        sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\{0,1\}\([^,\"}]*\).*/\1/p" |
        head -n 1 |
        tr -d '\r'
}

status_command() {
    RUNNING=false
    PID=""
    if pid_is_ours; then
        RUNNING=true
        PID="$(cat "$PIDFILE" 2>/dev/null)"
    fi

    STATUS_JSON=""
    PREFS_JSON=""
    if [ "$RUNNING" = true ]; then
        STATUS_JSON="$($TAILSCALE --socket="$SOCKET" status --json 2>/dev/null)"
        PREFS_JSON="$($TAILSCALE --socket="$SOCKET" debug prefs 2>/dev/null)"
    fi

    BACKEND_STATE="$(json_value "$STATUS_JSON" BackendState)"
    [ -n "$BACKEND_STATE" ] || {
        if [ "$RUNNING" = true ]; then
            BACKEND_STATE=Starting
        else
            BACKEND_STATE=Stopped
        fi
    }

    IPV4="$($TAILSCALE --socket="$SOCKET" ip -4 2>/dev/null | head -n 1)"
    IPV6="$($TAILSCALE --socket="$SOCKET" ip -6 2>/dev/null | head -n 1)"
    VERSION="$("$MODDIR/bin/tailscaled" --version 2>/dev/null | head -n 1)"
    MODULE_VERSION="$(sed -n 's/^version=//p' "$MODDIR/module.prop" | head -n 1)"
    COMMIT="$(tr -d '\r\n ' < "$MODDIR/upstream_commit" 2>/dev/null)"

    INTEGRITY=unrecorded
    if [ -s "$MODDIR/binary-sha256" ]; then
        if verify_binary_hashes; then
            INTEGRITY=verified
        else
            INTEGRITY=modified
        fi
    fi

    INTERFACE=down
    ip link show tailscale0 >/dev/null 2>&1 && INTERFACE=up
    OFFICIAL_VPN=false
    official_tailscale_vpn_active && OFFICIAL_VPN=true

    field backend_state "$BACKEND_STATE"
    field running "$RUNNING"
    field pid "$PID"
    field ipv4 "$IPV4"
    field ipv6 "$IPV6"
    field tailscale_version "${VERSION:-unknown}"
    field module_version "${MODULE_VERSION:-unknown}"
    field upstream_commit "${COMMIT:-unknown}"
    field integrity "$INTEGRITY"
    field interface "$INTERFACE"
    field official_vpn "$OFFICIAL_VPN"
    field accept_dns "$(json_value "$PREFS_JSON" CorpDNS)"
    field accept_routes "$(json_value "$PREFS_JSON" RouteAll)"
    field shields_up "$(json_value "$PREFS_JSON" ShieldsUp)"
    field hostname "$(json_value "$PREFS_JSON" Hostname)"
}

require_running() {
    pid_is_ours || {
        echo "ERROR: Native tailscaled is not running."
        exit 1
    }
}

set_boolean() {
    FLAG="$1"
    VALUE="$2"
    case "$VALUE" in
        true|false) ;;
        *) echo "ERROR: Invalid setting value."; exit 2 ;;
    esac
    require_running
    "$TAILSCALE" --socket="$SOCKET" set "--$FLAG=$VALUE"
}

case "$1" in
    status)
        status_command
        ;;
    logs)
        tail -n 120 "$LOGFILE" 2>/dev/null || echo "No log entries yet."
        ;;
    diagnostics)
        status_command
        echo
        "$TAILSCALE" --socket="$SOCKET" status 2>&1 || true
        echo
        ip addr show tailscale0 2>&1 || true
        ;;
    start)
        if official_tailscale_vpn_active; then
            echo "ERROR: Disconnect the official Tailscale Android app first."
            exit 1
        fi
        start_daemon && echo "Native tailscaled started."
        ;;
    stop)
        stop_daemon
        echo "Native tailscaled stopped."
        ;;
    restart)
        if official_tailscale_vpn_active; then
            echo "ERROR: Disconnect the official Tailscale Android app first."
            exit 1
        fi
        stop_daemon
        start_daemon && echo "Native tailscaled restarted."
        ;;
    login)
        require_running
        LOGIN_LOG="$BASE/webui-login.log"
        LOGIN_PIDFILE="$BASE/webui-login.pid"
        LOGIN_PID="$(cat "$LOGIN_PIDFILE" 2>/dev/null)"
        if [ -n "$LOGIN_PID" ] && kill -0 "$LOGIN_PID" 2>/dev/null; then
            cat "$LOGIN_LOG" 2>/dev/null
            exit 0
        fi
        : > "$LOGIN_LOG"
        nohup "$TAILSCALE" --socket="$SOCKET" up --qr --qr-format=small \
            > "$LOGIN_LOG" 2>&1 &
        echo "$!" > "$LOGIN_PIDFILE"
        I=0
        while [ ! -s "$LOGIN_LOG" ] && [ "$I" -lt 8 ]; do
            sleep 1
            I=$((I + 1))
        done
        cat "$LOGIN_LOG" 2>/dev/null
        ;;
    verify)
        if verify_binary_hashes; then
            echo "Installed binaries match their recorded SHA-256 hashes."
        else
            echo "ERROR: An installed binary does not match its recorded SHA-256 hash."
            exit 1
        fi
        ;;
    set)
        case "$2" in
            accept-dns) set_boolean accept-dns "$3" ;;
            accept-routes) set_boolean accept-routes "$3" ;;
            shields-up) set_boolean shields-up "$3" ;;
            hostname)
                HOSTNAME_VALUE="$3"
                [ "${#HOSTNAME_VALUE}" -le 63 ] || {
                    echo "ERROR: Hostname must be 63 characters or fewer."
                    exit 2
                }
                case "$HOSTNAME_VALUE" in
                    ""|*[!A-Za-z0-9.-]*|.*|-*|*..*|*.|*-)
                        echo "ERROR: Use only letters, numbers, dots, and hyphens."
                        exit 2
                        ;;
                esac
                require_running
                "$TAILSCALE" --socket="$SOCKET" set "--hostname=$HOSTNAME_VALUE"
                ;;
            *) echo "ERROR: Unknown setting."; exit 2 ;;
        esac
        ;;
    *)
        echo "Usage: $0 {status|logs|diagnostics|start|stop|restart|login|verify|set}"
        exit 2
        ;;
esac

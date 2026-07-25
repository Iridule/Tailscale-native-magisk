#!/system/bin/sh

ui_print "*******************************"
ui_print " Native Tailscale TUN module"
ui_print "*******************************"

[ "$ARCH" = "arm64" ] || abort "This package currently supports ARM64 only."

RAW=https://raw.githubusercontent.com/android-kxxt/external_tailscale_prebuilt/main
mkdir -p "$MODPATH/bin"
PRE_COMMIT_FILE="$MODPATH/.upstream-commit-before"
POST_COMMIT_FILE="$MODPATH/.upstream-commit-after"

download_installer_file() {
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

is_elf_installer() {
    FILE="$1"
    MAGIC="$(
        dd if="$FILE" bs=4 count=1 2>/dev/null |
        od -An -tx1 2>/dev/null |
        tr -d ' \n'
    )"
    [ "$MAGIC" = "7f454c46" ]
}

valid_commit_marker_installer() {
    MARKER="$1"
    [ "${#MARKER}" -eq 40 ] || return 1
    case "$MARKER" in
        *[!0-9a-f]*)
            return 1
            ;;
    esac
}

ui_print "- Fetching current patched binaries"

FETCHED=false
if download_installer_file "$RAW/commit" "$PRE_COMMIT_FILE"; then
    PRE_COMMIT="$(tr -d '\r\n ' < "$PRE_COMMIT_FILE")"

    if valid_commit_marker_installer "$PRE_COMMIT" &&
        download_installer_file \
            "$RAW/arm64/tailscale?commit=$PRE_COMMIT" \
            "$MODPATH/bin/tailscale" &&
        download_installer_file \
            "$RAW/arm64/tailscaled?commit=$PRE_COMMIT" \
            "$MODPATH/bin/tailscaled" &&
        download_installer_file "$RAW/commit" "$POST_COMMIT_FILE"
    then
        POST_COMMIT="$(tr -d '\r\n ' < "$POST_COMMIT_FILE")"
        if valid_commit_marker_installer "$POST_COMMIT" &&
            [ "$POST_COMMIT" = "$PRE_COMMIT" ]
        then
            printf '%s\n' "$PRE_COMMIT" > "$MODPATH/upstream_commit"
            FETCHED=true
        else
            ui_print "- Upstream changed during download; discarding the download"
        fi
    fi
fi

rm -f "$PRE_COMMIT_FILE" "$POST_COMMIT_FILE"

if [ "$FETCHED" != true ]; then
    ui_print "- Download failed; looking for your existing tested binaries"
    rm -f "$MODPATH/upstream_commit"

    for SRC in \
        /data/local/tmp/ts-native \
        /data/adb/tailscale-native/bin \
        /data/adb/modules/native_tailscale/bin
    do
        if [ -x "$SRC/tailscale" ] && [ -x "$SRC/tailscaled" ]; then
            cp -f "$SRC/tailscale" "$MODPATH/bin/tailscale"
            cp -f "$SRC/tailscaled" "$MODPATH/bin/tailscaled"
            ui_print "- Reused binaries from $SRC"
            FETCHED=true
            break
        fi
    done
fi

[ "$FETCHED" = true ] || abort "Could not download or locate existing Tailscale binaries."

chmod 0755 "$MODPATH/bin/tailscale" "$MODPATH/bin/tailscaled"

is_elf_installer "$MODPATH/bin/tailscale" ||
    abort "tailscale is not a valid ELF executable."
is_elf_installer "$MODPATH/bin/tailscaled" ||
    abort "tailscaled is not a valid ELF executable."

TS_VERSION="$("$MODPATH/bin/tailscaled" --version 2>/dev/null | head -n 1)"
[ -n "$TS_VERSION" ] || abort "tailscaled could not execute on this device."
ui_print "- Installed Tailscale $TS_VERSION"

# Prevent any standalone launcher from running alongside the module.
# Magisk executes every executable file in service.d regardless of its suffix,
# so move legacy scripts fully outside that directory.
LEGACY_DIR=/data/adb/service.d-disabled
mkdir -p "$LEGACY_DIR"

MOVED_OLD=false
for OLD_SERVICE in \
    /data/adb/service.d/99-tailscale-native.sh \
    /data/adb/service.d/99-tailscale-native.sh.disabled \
    /data/adb/service.d/99-tailscale-native.sh.disabled-by-module
do
    if [ -e "$OLD_SERVICE" ]; then
        chmod 0644 "$OLD_SERVICE" 2>/dev/null
        mv -f "$OLD_SERVICE" "$LEGACY_DIR/" 2>/dev/null
        MOVED_OLD=true
    fi
done

if [ "$MOVED_OLD" = true ]; then
    ui_print "- Moved old standalone launcher outside service.d"
fi

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/bin/tailscale" 0 0 0755
set_perm "$MODPATH/bin/tailscaled" 0 0 0755
set_perm "$MODPATH/common.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755

ui_print "- Your state remains at /data/adb/tailscale-native"
ui_print "- Keep the official Tailscale app disconnected"
ui_print "- Reboot after installation"
ui_print "- Use the module Action button for upstream updates"

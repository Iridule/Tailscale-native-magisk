#!/system/bin/sh

MODDIR=${0%/*}
. "$MODDIR/common.sh"

stop_daemon

# Preserve the authenticated node identity and logs in:
# /data/adb/tailscale-native
#
# Delete that directory manually only if you also want to erase the identity.

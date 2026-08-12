Native Tailscale TUN — Magisk bootstrap module v0.4.0

PURPOSE
Runs the android-kxxt patched tailscaled daemon as a root-native TUN service,
leaving Android's VpnService slot available for another VPN.

INSTALL
1. Disconnect the official Android Tailscale app.
2. Install this ZIP from Magisk > Modules > Install from storage.
3. Reboot.
4. Tap the module's Action button and open the displayed URL or scan its QR.
5. The module reuses:
   /data/adb/tailscale-native/tailscaled.state
   so your existing Tailscale node identity should remain logged in.

LOGIN AND UPDATES
On a fresh device, the Action button starts interactive Tailscale login. Once
the device is authenticated, the same button:
- checks android-kxxt/external_tailscale_prebuilt
- compares the upstream source commit marker
- downloads ARM64 tailscale and tailscaled
- rechecks the marker and aborts if upstream changed during the download
- verifies ELF format and that tailscaled executes
- records SHA-256 hashes
- backs up the current binaries
- restarts the daemon
- rolls back automatically if the new daemon fails to start

OPTIONAL WEBUI
Install KsuWebUIStandalone on Magisk to open the bundled dashboard. It shows
connection and integrity status, exposes safe Tailscale preferences, controls
the native service, checks binary updates, and displays recent logs. The
existing Magisk Action button remains available as a fallback.

SECURITY NOTE
The upstream repository currently publishes raw prebuilts without signed
releases or a signed checksum manifest. The updater therefore trusts HTTPS,
GitHub, and the android-kxxt repository. Updates are manual, never automatic
at boot. Review upstream changes before pressing Action if this is a concern.

STATE AND UNINSTALL
Uninstalling stops the daemon but intentionally preserves:
  /data/adb/tailscale-native
Delete that directory manually only when you want to erase the node identity.

TROUBLESHOOTING
Log:
  /data/adb/tailscale-native/tailscaled.log

Status:
  su -c '/data/adb/modules/native_tailscale/bin/tailscale     --socket=/data/adb/tailscale-native/tailscaled.sock status'

Version:
  su -c '/data/adb/modules/native_tailscale/bin/tailscaled --version'

Interface:
  su -c 'ip addr show tailscale0'

The native daemon will not start while Android reports the official
com.tailscale.ipn VPN as active.

LIMITATIONS
- ARM64 only.
- The module version describes the bootstrap scripts, not the Tailscale
  version downloaded at installation time.
- The same ZIP can install a newer upstream Tailscale build on a later date.
- Another VPN can still conflict through DNS, routes, or kill-switch policy.
- The release ZIP checksum does not verify binaries downloaded afterward.

MIGRATION FIX IN 0.2.1
Older standalone launchers are moved to /data/adb/service.d-disabled.
Simply changing a filename suffix does not disable an executable service.d
script, because Magisk uses its executable permission rather than the suffix.
The module also stops a legacy daemon before removing or recreating its socket.

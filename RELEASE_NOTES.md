# Native Tailscale TUN v0.4.3-bootstrap

This release gives the local dashboard a cyber-terminal interface while
keeping the tested v0.4.2 service, login, status, and update behavior intact.

## What it does

- Runs the android-kxxt patched `tailscaled` as a root-native `tailscale0`
  interface.
- Leaves Android's `VpnService` slot available for another VPN.
- Reuses the authenticated state under `/data/adb/tailscale-native`.
- Provides a local, offline dashboard with connection and integrity status.
- Adds safe settings for DNS, subnet routes, shields-up, and hostname.
- Provides login, service, integrity, log, and diagnostic controls.
- Records installed binary SHA-256 hashes and blocks updates after unexpected
  modification.
- Makes Magisk Action exclusively open the dashboard.
- Moves Tailscale binary updates into the dashboard.
- Adds log clearing and faster status refresh.
- Adds a high-contrast, responsive, fully offline visual design.
- Displays both a large tappable sign-in link and the full selectable
  authentication URL for copy-and-paste fallback.
- Uses Magisk's built-in update notification mechanism for module releases.
- Rechecks the upstream source marker after downloads to reject mixed updates.

## WebUI compatibility

The bundled `webroot` targets KsuWebUIStandalone running on Magisk. All assets
are packaged locally; no external fonts, scripts, analytics, or trackers are
loaded.

Magisk Action opens this module directly in KsuWebUIStandalone. The dashboard
presents a tappable Tailscale sign-in button instead of terminal QR output.
The complete URL remains visible and selectable if WebView navigation is not
available on a particular device.

## Important

- ARM64 only.
- The ZIP downloads patched executables during installation; it does not bundle
  them.
- Disconnect the official Android Tailscale app before installation and login.
- A second VPN can still conflict through DNS, routes, or kill-switch policy.
- The module version and release checksum describe the bootstrap ZIP, not the
  Tailscale binaries downloaded at installation time.
- Review [SECURITY.md](SECURITY.md) before using the updater.

## SHA-256

```text
a1400e89d5e56fbe38c45dfd6f95f40c04a9278ef209ef98260ab63dd206d3cd
```

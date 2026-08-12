# Native Tailscale TUN v0.4.4-bootstrap

This release clarifies Android's native DNS limitation, cleans up updater
results, and keeps pending login links clickable on repeated Sign in taps.

## What it does

- Runs the android-kxxt patched `tailscaled` as a root-native `tailscale0`
  interface.
- Leaves Android's `VpnService` slot available for another VPN.
- Reuses the authenticated state under `/data/adb/tailscale-native`.
- Provides a local, offline dashboard with connection and integrity status.
- Adds safe settings for subnet routes, shields-up, and hostname.
- Provides login, service, integrity, log, and diagnostic controls.
- Records installed binary SHA-256 hashes and blocks updates after unexpected
  modification.
- Makes Magisk Action exclusively open the dashboard.
- Moves Tailscale binary updates into the dashboard.
- Adds log clearing and faster status refresh.
- Adds a high-contrast, responsive, fully offline visual design.
- Displays both a large tappable sign-in link and the full selectable
  authentication URL for copy-and-paste fallback.
- Reuses that clickable link while an authentication command is still pending.
- Shows a concise connection summary after binary update checks instead of
  exposing an expected Android DNS health warning as an apparent failure.
- Places the raw status and a plain-language Android DNS explanation under
  Diagnostics.
- Removes the ineffective DNS switch and keeps `accept-dns=false` because the
  native Android build cannot install system-wide MagicDNS.
- Adds a Tailnet Admin button that opens the official Machines page in the
  device's normal browser without exposing arbitrary URLs.
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
34323763c2a9a517da3c608d080359a36f0a854711feedaffae7629ec3ef1d5b
```

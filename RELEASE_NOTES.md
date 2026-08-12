# Native Tailscale TUN v0.4.1-bootstrap

This release fixes authentication from the Magisk Action screen and dashboard.

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
- Retains the Magisk Action login and updater as a fallback.
- Uses Magisk's built-in update notification mechanism for module releases.
- Rechecks the upstream source marker after downloads to reject mixed updates.

## WebUI compatibility

The bundled `webroot` targets KsuWebUIStandalone running on Magisk. All assets
are packaged locally; no external fonts, scripts, analytics, or trackers are
loaded.

When authentication is required, Magisk Action now opens this module directly
in KsuWebUIStandalone. The dashboard presents a tappable Tailscale sign-in
button instead of terminal QR output. If the WebUI cannot be opened, Action
falls back to printing Tailscale's plain authentication URL.

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
5c480d54110fecd4898ae6cb36095797b75c1109144a94eaa2f4caf984e9d632
```

# Native Tailscale TUN v0.4.2-bootstrap

This release simplifies Action behavior, speeds up status refresh, and makes
the difference between historical logs and current authentication explicit.

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
- Uses Magisk's built-in update notification mechanism for module releases.
- Rechecks the upstream source marker after downloads to reject mixed updates.

## WebUI compatibility

The bundled `webroot` targets KsuWebUIStandalone running on Magisk. All assets
are packaged locally; no external fonts, scripts, analytics, or trackers are
loaded.

Magisk Action opens this module directly in KsuWebUIStandalone. The dashboard
presents a tappable Tailscale sign-in button instead of terminal QR output.

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
03106f2413930bb9b2f06b6243ae3d9855c39ea314093504719c4d519a72bda5
```

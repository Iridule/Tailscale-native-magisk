# Native Tailscale TUN v0.4.0-bootstrap

This release adds an optional dashboard for Magisk + KsuWebUIStandalone and
strengthens installed-binary integrity checking.

## What it does

- Runs the android-kxxt patched `tailscaled` as a root-native `tailscale0`
  interface.
- Leaves Android's `VpnService` slot available for another VPN.
- Reuses the authenticated state under `/data/adb/tailscale-native`.
- Provides a local, offline dashboard with connection and integrity status.
- Adds safe settings for DNS, subnet routes, shields-up, and hostname.
- Provides login, service, update, log, and diagnostic controls.
- Records installed binary SHA-256 hashes and blocks updates after unexpected
  modification.
- Retains the Magisk Action login and updater as a fallback.
- Rechecks the upstream source marker after downloads to reject mixed updates.

## WebUI compatibility

The bundled `webroot` targets KsuWebUIStandalone running on Magisk. All assets
are packaged locally; no external fonts, scripts, analytics, or trackers are
loaded.

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
277ab319c19b1c54ded410b1913df52e63e497a072feecb7432344cba8ad9032
```

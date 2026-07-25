# Native Tailscale TUN v0.2.1-bootstrap

First public bootstrap release of the ARM64 Native Tailscale TUN Magisk module.

## What it does

- Runs the android-kxxt patched `tailscaled` as a root-native `tailscale0`
  interface.
- Leaves Android's `VpnService` slot available for another VPN.
- Reuses the authenticated state under `/data/adb/tailscale-native`.
- Provides a manual Magisk Action updater with validation, backup, restart, and
  rollback.
- Rechecks the upstream source marker after downloads to reject mixed updates.

## v0.2.1 fix

This build moves older standalone launchers completely outside Magisk's
`service.d` directory and stops their daemon before recreating the native
socket. Executable scripts inside `service.d` can still run regardless of a
`.disabled` filename suffix.

## Important

- ARM64 only.
- The ZIP downloads patched executables during installation; it does not bundle
  them.
- Disconnect the official Android Tailscale app before installation.
- A second VPN can still conflict through DNS, routes, or kill-switch policy.
- The module version and release checksum describe the bootstrap ZIP, not the
  Tailscale binaries downloaded at installation time.
- Review [SECURITY.md](SECURITY.md) before using the updater.

## SHA-256

```text
7b512622049f0a32acf3520d3ffa049c296348b8807585789f5396b2eb524e4a
```

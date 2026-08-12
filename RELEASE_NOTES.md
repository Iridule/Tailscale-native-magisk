# Native Tailscale TUN v0.3.0-bootstrap

This release fixes onboarding on a clean or reformatted device.

## What it does

- Runs the android-kxxt patched `tailscaled` as a root-native `tailscale0`
  interface.
- Leaves Android's `VpnService` slot available for another VPN.
- Reuses the authenticated state under `/data/adb/tailscale-native`.
- Uses the Magisk Action button for interactive QR/browser login when the
  daemon reports `NeedsLogin` or `NoState`.
- Uses that same button for validated, rollback-capable updates after login.
- Rechecks the upstream source marker after downloads to reject mixed updates.

## Root cause and fix

The boot service started the daemon but intentionally could not authenticate
it. The previous Action script only checked for binary updates, so a fresh
state remained in `NeedsLogin`. Action now detects that state, starts
`tailscale up --qr`, and explains when administrator approval is required.

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
314cc17cbc458223cfbabc42c72aea32f5e8a7eed7de90b21be8bc82af84bece
```

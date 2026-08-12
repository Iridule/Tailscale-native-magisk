# Changelog

## 0.4.0-bootstrap — 2026-08-12

- Add an offline dashboard for Magisk users running KsuWebUIStandalone.
- Show daemon, TUN interface, connection, version, source revision, and binary
  integrity status.
- Add controls for login, start, stop, restart, update, diagnostics, and logs.
- Add safe settings for Tailscale DNS, subnet routes, shields-up, and hostname.
- Record binary SHA-256 hashes during installation and after updates.
- Block binary updates when installed files no longer match their recorded
  hashes.
- Keep the existing Magisk Action flow as a fallback.

## 0.3.0-bootstrap — 2026-08-12

- Detect a fresh device's `NeedsLogin`/`NoState` state from the module Action.
- Start interactive `tailscale up --qr` login from the Magisk Action screen.
- Explain `NeedsMachineAuth` instead of silently running the updater.
- Start the daemon from Action when boot startup has not left it running.
- Record an actionable authentication message in the daemon log.

## 0.2.1-bootstrap — 2026-07-24

- Move legacy standalone launchers completely outside `service.d`.
- Stop legacy native daemons before cleaning or recreating their socket.
- Preserve the authenticated Tailscale state during upgrades and uninstall.
- Retain manual, validated, rollback-capable upstream binary updates.
- Recheck the upstream source marker around install and update downloads.
- Validate source markers as exact 40-character lowercase hexadecimal values.
- Avoid signaling a reused PID that no longer belongs to the module daemon.
- Use a portable boot-completion wait across Magisk versions.
- Clarify bootstrap-version, checksum, and dual-VPN limitations.

## 0.2.0-bootstrap — 2026-07-24

- Add a Magisk bootstrap installer for ARM64 patched Tailscale binaries.
- Start `tailscaled` as a root-native TUN service after Android networking is
  ready.
- Add a Magisk Action updater with ELF validation, backup, restart, and
  rollback.

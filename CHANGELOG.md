# Changelog

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

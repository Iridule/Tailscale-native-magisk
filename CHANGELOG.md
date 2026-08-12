# Changelog

## 0.4.5-bootstrap — 2026-08-12

- Recover saved sessions automatically after Start or Restart, including after
  an abrupt daemon kill, by retrying the control-plane refresh while the new
  daemon settles.
- Treat transient `NeedsLogin`/`NoState` startup states as session restoration
  instead of immediately prompting for authentication.
- Disable the login action during recovery and show a green **Signed in**
  state once the daemon reaches `Running`.
- Use a bare `tailscale up` for genuine authentication so existing non-default
  subnet-route, shields-up, hostname, and DNS preferences are preserved.
- Recheck live daemon state during login and report when the saved session has
  already recovered instead of claiming that a sign-in URL is unavailable.
- Remove the mismatched accent-colored bottom-right corner decoration from
  dashboard cards.

## 0.4.4-bootstrap — 2026-08-12

- Return pending authentication URLs through the same `login_url=` WebUI
  protocol as new login attempts, keeping the clickable sign-in control on
  repeated taps.
- Replace raw `tailscale status` output in the binary updater with a concise
  live state, IP, hostname, and TUN summary.
- Explain the native Android no-op OS DNS configurator and its expected
  low-severity base-DNS warning in Diagnostics.
- Remove the ineffective Tailscale DNS switch and keep `accept-dns=false`
  during daemon startup and dashboard login, leaving Android's existing DNS
  untouched.
- Add an allowlisted Tailnet Admin action that opens the official Tailscale
  Machines page in the device's normal browser.

## 0.4.3-bootstrap — 2026-08-12

- Restyle the offline dashboard with a responsive cyber-terminal interface,
  high-contrast connection matrix, and explicit ON/OFF switches.
- Keep all fonts, icons, scripts, and visual effects local to the module.
- Respect the device's reduced-motion accessibility setting.
- Show Tailscale authentication as a large tappable link and repeat the full,
  selectable URL underneath as a copy-and-paste fallback.
- Preserve the tested helper allowlist, live status, integrity, service,
  settings, updater, and real daemon-log behavior beneath the new design.

## 0.4.2-bootstrap — 2026-08-12

- Make Magisk Action exclusively launch the KsuWebUIStandalone dashboard.
- Move manual Tailscale binary updates into a clearly labeled dashboard
  control while leaving module releases to Magisk's built-in updater.
- Make normal dashboard refreshes fast by caching the last integrity result;
  hashing now runs separately on initial load or explicit verification.
- Ask the live daemon for a control-plane refresh before rechecking status so
  remotely removed machines can transition out of a stale running state.
- Label daemon logs as historical rather than current authentication truth.
- Add a Clear log control.

## 0.4.1-bootstrap — 2026-08-12

- Open this module directly in KsuWebUIStandalone when Magisk Action detects
  that authentication is required.
- Replace terminal QR output with a tappable authentication button inside the
  dashboard.
- Keep `tailscale up` running in the background while browser authentication
  completes.
- Fall back to printing the plain authentication URL when KsuWebUIStandalone
  is not installed or cannot be opened.
- Derive fresh node names from Android's configured device name, Bluetooth
  name, product market name, or model instead of using `node`/`localhost`.
- Prefill the dashboard hostname with that derived device name while retaining
  the manual hostname control.

## 0.4.0-bootstrap — 2026-08-12

- Add an offline dashboard for Magisk users running KsuWebUIStandalone.
- Show daemon, TUN interface, connection, version, source revision, and binary
  integrity status.
- Add controls for login, start, stop, restart, diagnostics, and logs.
- Add safe settings for Tailscale DNS, subnet routes, shields-up, and hostname.
- Record binary SHA-256 hashes during installation and after updates.
- Block binary updates when installed files no longer match their recorded
  hashes.
- Keep the existing Magisk Action flow as a fallback.
- Use Magisk's built-in `updateJson` notification flow for module releases;
  module updating is not duplicated inside the dashboard.
- Recover ownership of a managed daemon when its PID file is stale or missing,
  and refuse duplicate starts while another `tailscaled` or `tailscale0`
  already exists.

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

# Native Tailscale TUN v0.4.6-bootstrap

This maintenance release repairs dashboard login when the daemon has already
generated an authentication URL but an older background-login result remains
in the persistent module state.

## Root cause

The daemon was successfully reaching Tailscale and producing a valid
authentication URL. The dashboard checked a stored login PID and log before it
checked that live URL. A stale or recycled PID could therefore replay an old
`tailscale up` incomplete-flags error instead of presenting the current link.

## Changes

- Live daemon `AuthURL` is now the first source for the clickable sign-in link.
- Login PIDs are trusted only when `/proc` identifies the exact module-owned
  `tailscale up` process.
- Stop, Start, and Restart clean up orphaned background login commands.
- Stale login output can no longer override a live URL or Running state.
- The fallback remains a bare `tailscale up`, preserving subnet-route,
  shields-up, hostname, DNS, and other non-default preferences.

## Validation

- A mocked live `NeedsLogin` status returns its clickable URL without running
  another login command.
- A live `Running` status reports that the device is already signed in.
- A stale PID and old error log are ignored, and the fallback invokes exactly
  bare `tailscale up`.
- Shell syntax, JavaScript syntax, mobile WebUI regression, archive comparison,
  and release checksum checks pass.

## Important

- ARM64 only.
- Reboot after installing so Magisk activates every updated module script.
- Disconnect the official Android Tailscale app before using the native daemon.
- Existing identity under `/data/adb/tailscale-native` remains preserved.

## SHA-256

```text
82e53e0326c30c4efec6b629b30abc2cfeafdf99fd71108b205020ab7a1efe1e
```

# Native Tailscale TUN v0.4.5-bootstrap

This maintenance release fixes misleading authentication prompts while the
native daemon restores an existing session after Start, Restart, or an abrupt
process kill.

## Changes

- Start and Restart now retry the same fresh network-map request used by the
  dashboard refresh button while the replacement daemon settles.
- Temporary `NeedsLogin` and `NoState` startup states display **Restoring** and
  cannot launch an unnecessary login attempt.
- Connected devices display a green **Signed in** state.
- Genuine authentication uses a bare `tailscale up`, preserving all existing
  non-default Tailscale preferences and avoiding the incomplete-flags error.
- Login checks live state and reports when the saved session has already
  recovered.
- Dashboard cards no longer have an inconsistent accent-colored lower corner.

## Validation

- Shell syntax checks pass for all module scripts.
- JavaScript syntax and whitespace checks pass.
- The mobile WebUI regression covers Start and Restart transitions through
  `NeedsLogin` to `Running`, the disabled Restoring state, genuine login, and
  the final Signed in state.

## Important

- ARM64 only.
- Disconnect the official Android Tailscale app before using the native daemon.
- The ZIP downloads the current patched binaries during installation; it does
  not bundle them.
- Existing identity under `/data/adb/tailscale-native` remains preserved.

## SHA-256

```text
1191babf3fe5166116a6604e5f4f7e52c80678fc137f75bf167e2163e42805f0
```

# Security

## Upstream binary trust

This module is a bootstrap package. It downloads ARM64 executables from
[`android-kxxt/external_tailscale_prebuilt`](https://github.com/android-kxxt/external_tailscale_prebuilt)
during installation and when the user manually runs the module Action.

The upstream repository currently publishes raw prebuilts without a signed
release or signed checksum manifest. The module therefore relies on HTTPS,
GitHub, and control of the upstream repository. ELF-header and execution checks
detect corrupt or non-executable downloads, but they do not establish binary
provenance.

Updates are never automatic at boot. Users with a stricter threat model should
review the upstream source and build process before installing or updating.
Installation and manual updates recheck the upstream source marker after both
binaries download and abort if it changed during the operation. This prevents
a mixed download during an upstream update, but it is not a cryptographic
provenance check.

The SHA-256 value published with the GitHub release verifies the bootstrap ZIP
only. Hashes recorded under `/data/adb/tailscale-native` document the binaries
received by that device; neither is an independently signed upstream manifest.

## Local privileges

The daemon runs as root and manages a native TUN interface. Module state,
socket, PID, logs, and update hashes are stored under:

```text
/data/adb/tailscale-native
```

The directory is mode `0700` and files are created under a restrictive umask.

## WebUI boundary

The optional dashboard is opened by KsuWebUIStandalone and therefore runs with
the root command bridge that application provides. The dashboard ships no
remote assets and exposes no arbitrary command input. Its controls call a
module-owned helper with an allowlist of status, service, integrity, log, and
validated preference operations. Hostnames and boolean values are validated
again in the root helper before they reach the Tailscale CLI.

Only install KsuWebUIStandalone from a source you trust and keep its root
permission scoped appropriately. Any application with an unrestricted root
bridge is part of the device's trusted computing base.

## Reporting a vulnerability

Open a GitHub issue only for non-sensitive reports. Do not include credentials,
authentication URLs, Tailscale state files, private IP addresses, or logs that
identify private tailnet devices. For a sensitive report, contact the
maintainer privately through the contact method listed on their GitHub
profile.

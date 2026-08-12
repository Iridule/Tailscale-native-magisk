# Native Tailscale TUN for Magisk

**Created with the help of OpenAI**

An experimental ARM64 Magisk bootstrap module that runs the patched
[`android-kxxt/external_tailscale_prebuilt`](https://github.com/android-kxxt/external_tailscale_prebuilt)
`tailscaled` daemon as a root-native `tailscale0` interface. Because it does
not use Android's `VpnService`, the Android VPN slot remains available for
another VPN.

> [!WARNING]
> This is an independent community project. It is not affiliated with or
> endorsed by Tailscale Inc., android-kxxt, Magisk, or OpenAI. Root networking
> changes can interrupt connectivity; keep a recovery path and a current
> backup.

## Requirements

- Rooted ARM64 Android device
- Magisk with module support
- Working `/dev/tun`
- Internet access during installation
- Official Android Tailscale app disconnected

The bootstrap ZIP does **not** bundle Tailscale executables. During
installation it downloads the current-at-install-time ARM64 `tailscale` and
`tailscaled` binaries from the android-kxxt repository, validates their ELF
headers, confirms that `tailscaled --version` executes, and aborts the
download if the upstream source marker changes partway through.

The module version identifies these bootstrap scripts, not the downloaded
Tailscale version. Consequently, the same module ZIP can install a newer
Tailscale build on a later date.

## Install

1. Download `native-tailscale-magisk-bootstrap-v0.3.0.zip` from
   [Releases](../../releases).
2. Disconnect the official Android Tailscale app.
3. Open **Magisk → Modules → Install from storage** and select the ZIP.
4. Reboot.
5. Open **Magisk → Modules** and tap this module's **Action** button.
6. Open the displayed login URL or scan its QR code and finish signing in.

If this device was already configured by the standalone native setup, the
module reuses:

```text
/data/adb/tailscale-native/tailscaled.state
```

The Action button detects an unauthenticated fresh install and runs Tailscale's
interactive QR login. On an already authenticated installation, it checks for
upstream binary updates instead. You can also authenticate from a root shell:

```sh
su -c '/data/adb/modules/native_tailscale/bin/tailscale \
  --socket=/data/adb/tailscale-native/tailscaled.sock up'
```

## Check status

```sh
su -c '/data/adb/modules/native_tailscale/bin/tailscale \
  --socket=/data/adb/tailscale-native/tailscaled.sock status'
```

```sh
su -c '/data/adb/modules/native_tailscale/bin/tailscaled --version'
```

```sh
su -c 'ip addr show tailscale0'
```

Log file:

```text
/data/adb/tailscale-native/tailscaled.log
```

## Update the native binaries

Tap the module's **Action** button in Magisk. If the device needs login, the
button starts interactive login first. Once authenticated, updates are manual
and never run automatically at boot. The updater:

- compares the installed and upstream source commit markers;
- downloads the new ARM64 binaries;
- rechecks the marker and aborts if upstream changed during the download;
- validates ELF format and execution;
- records SHA-256 hashes;
- backs up the current binaries;
- restarts the daemon; and
- rolls back if the new daemon fails to start.

## Security model

The upstream prebuilt repository currently provides raw binaries without a
signed release or signed checksum manifest. Installation and updates therefore
trust HTTPS, GitHub, and the android-kxxt repository. Review upstream changes
before installing or pressing **Action** if this trust model does not fit your
needs. The recorded SHA-256 hashes document what was downloaded; they are not
checked against an independently trusted upstream manifest.

## Known limitations

- ARM64 only.
- This is an experimental module tested on a limited number of devices.
- The official Android Tailscale app must remain disconnected while the native
  daemon is running.
- Keeping Android's `VpnService` slot free does not guarantee that every second
  VPN will coexist cleanly. DNS settings, routes, kill switches, and the other
  VPN's policy can still conflict.
- The upstream binaries are mutable downloads from the upstream repository,
  subject to the trust model described above.

## Recovery

If native Tailscale causes a boot or networking problem, disable or remove the
module in Magisk and reboot. Uninstalling preserves
`/data/adb/tailscale-native`, so reinstalling normally reuses the authenticated
node identity. Delete that directory only when you intentionally want to erase
the identity.

## Uninstall

Removing the module stops its daemon but intentionally preserves
`/data/adb/tailscale-native`, including the authenticated node identity and
logs. Delete that directory manually only if you also want to erase the
identity.

## v0.2.1 migration fix

Older standalone launchers are moved out of `/data/adb/service.d` and into
`/data/adb/service.d-disabled`. Merely changing a script's filename suffix does
not disable it when it remains executable: Magisk executes executable files in
`service.d` regardless of suffix. The module also stops a legacy daemon before
recreating its socket.

## Verification

This checksum verifies the bootstrap ZIP only. It does not verify the
Tailscale binaries downloaded later during installation or an update.

```text
314cc17cbc458223cfbabc42c72aea32f5e8a7eed7de90b21be8bc82af84bece  native-tailscale-magisk-bootstrap-v0.3.0.zip
```

See [SECURITY.md](SECURITY.md), [CHANGELOG.md](CHANGELOG.md), and
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for additional details.

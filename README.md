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

1. Download `native-tailscale-magisk-bootstrap-v0.4.3.zip` from
   [Releases](../../releases).
2. Disconnect the official Android Tailscale app.
3. Open **Magisk → Modules → Install from storage** and select the ZIP.
4. Reboot.
5. Install KsuWebUIStandalone if it is not already installed.
6. Open **Magisk → Modules** and tap this module's **Action** button.
7. In the dashboard, tap **Sign in**, then **Open Tailscale sign-in**.

## Optional dashboard

Magisk users can install
[`KsuWebUIStandalone`](https://github.com/KOWX712/KsuWebUIStandalone) to open
the module's bundled dashboard. It works offline and provides:

- connection, daemon, TUN interface, version, and upstream revision status;
- recorded SHA-256 integrity status for both installed binaries;
- Tailscale DNS, subnet-route, shields-up, and hostname preferences;
- login, start, stop, restart, integrity, and native-binary update actions;
- historical daemon logs with refresh/clear controls and live diagnostics; and
- a local cyber-terminal theme with high-contrast status indicators and no
  externally loaded fonts or assets.

The dashboard calls only the module's allowlisted helper operations. It does
not provide an arbitrary command field or store authentication secrets.

Magisk checks `update.json` and displays module release notifications through
its normal module interface. The dashboard does not duplicate module updates.

If this device was already configured by the standalone native setup, the
module reuses:

```text
/data/adb/tailscale-native/tailscaled.state
```

The Action button only opens the dashboard. You can also authenticate from a
root shell:

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

Open the dashboard and tap **Update Tailscale**. Updates are manual and never
run automatically at boot. The updater:

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
before installing or selecting **Update Tailscale** if this trust model does
not fit your needs. The recorded SHA-256 hashes document what was downloaded; they are not
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
a1400e89d5e56fbe38c45dfd6f95f40c04a9278ef209ef98260ab63dd206d3cd  native-tailscale-magisk-bootstrap-v0.4.3.zip
```

See [SECURITY.md](SECURITY.md), [CHANGELOG.md](CHANGELOG.md), and
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for additional details.

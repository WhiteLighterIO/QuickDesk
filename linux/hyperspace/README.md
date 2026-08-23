# HyperSpace Linux subsystem for QuickDesk

This directory is the WhiteLighterIO-controlled Linux subsystem used by HyperSpace Screen3.

## Scope

- Linux first target: Gentoo + OpenRC + X11 (`DISPLAY=:0`).
- Existing logged-in physical desktop first.
- Chromium Remoting capture/input core without embedding the QuickDesk Qt/QML UI.
- Host binary target: `hyperspace-chromoting-host`.
- HyperSpace Screen3 remains the viewer/product UI.

## Security boundary

QuickDesk device IDs, access codes, native-message admission, or upstream signaling are not HyperSpace authorization.

Before any network admission, the Linux host must be gated by a HyperSpace-owned broker carrying authoritative:

- `orgId`
- `machineId`
- `agentId`
- `sessionId`

The outer HyperSpace control path remains strict custom mTLS + Cloudflare Access assertion. There is no HTTP fallback and no automatic fallback to legacy WebRTC/RDP.

## Display contract

The Collector is authoritative for display inventory. The subsystem must:

- require at least one reported display;
- select the reported primary display by default;
- use its native width/height;
- never synthesize `1024x768`;
- retain every other reported display for switching;
- reject a selected display ID that is not present in the Collector inventory.

## Chromium Remoting source gate

Reviewed Linux Chromium Remoting source is staged under:

`3rdparty/quickdesk-remoting/linux-source`

until a cleaner repository packaging decision is made. HyperSpace build tooling must fail closed if the required source/BUILD.gn files are absent. It must not silently clone an external upstream during a product build.

## Runtime sequence

1. Collector receives/authorizes a HyperSpace remote-session command through the existing secure control plane.
2. Collector creates the local host configuration and passes it to the Linux subsystem over local IPC/process launch only.
3. `hyperspace-chromoting-host` validates the configuration before capture/input starts.
4. Screen3 connects through the HyperSpace Chromoting adapter.
5. Any identity, display, or broker mismatch terminates the session; no legacy fallback is attempted.

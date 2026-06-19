# Codex Resets Expire

Native macOS menu bar utility for checking Codex rate-limit reset credits and their expiration times.

The app reads `~/.codex/auth.json`, calls the Codex reset-credit endpoint with the local ChatGPT token, and displays only parsed reset-credit metadata. It does not store tokens.

After launch, the app opens a small native dashboard. Closing that window keeps the app running in the background. You can also look for `Codex <count>` in the macOS menu bar, unless a menu-bar manager hides new items.

## Build And Run

```bash
./script/build_and_run.sh
```

The script builds the SwiftPM executable, stages `dist/CodexResetsExpire.app`, and launches it as a menu-bar-only app.

## Verify

```bash
swift test
./script/build_and_run.sh --verify
```

## Install To Applications

```bash
./script/install_app.sh
```

This installs the staged app bundle to `/Applications/Codex Resets.app` and opens it.

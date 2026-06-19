# Codex Resets Expire

Native macOS menu-bar app for checking Codex reset credits and expiration times.

It reads `~/.codex/auth.json`, uses the local ChatGPT access token and account
ID to call the Codex reset-credit endpoint, and renders the parsed credit
metadata in a status-item popover. It does not store tokens.

- **Menu bar**: provides a native status item that opens the reset-credit
  popover.
- **Refresh**: fetches credit state from
  `https://chatgpt.com/backend-api/wham/rate-limit-reset-credits`.
- **Expiration view**: lists parsed reset credits and their expiry status.
- **Fallback display**: keeps the last parsed credit snapshot for display after
  refresh failures.
- **Native app bundle**: builds and stages a menu-bar-only macOS app.

## Install

```sh
./script/install_app.sh
```

This builds the app, verifies it launches, installs it to
`/Applications/Codex Resets.app`, and opens it.

## Run

```sh
./script/build_and_run.sh
```

This builds the SwiftPM executable, stages `dist/CodexResetsExpire.app`, and
launches it as a menu-bar-only app.

## Verify

```sh
swift test
./script/build_and_run.sh --verify
```

The verification script launches the staged app and checks that the
`CodexResetsExpire` process is running.

## Development

```sh
swift build
swift test
./script/build_and_run.sh --logs
```

The package targets macOS 14 and uses SwiftPM. The app reads credentials from
the local Codex auth file at runtime; tests use fixtures and temporary files.

## Boundaries

This app is only for viewing Codex reset-credit metadata from the menu bar.

It does not redeem reset credits, modify Codex account state, store access
tokens, manage multiple accounts, or provide a Dock-oriented app workflow.

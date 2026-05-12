# DeepSeekBalanceBar Packaging

## Current package status

- App type: macOS menu bar app.
- Minimum macOS version: 14.0.
- Version: 1.0 (build 1).
- Local unsigned package script: `scripts/package_unsigned.sh`.
- Local unsigned output: `dist/DeepSeekBalanceBar-1.0-unsigned.zip`.

## Local unsigned package

Use this for internal testing on the same machine or trusted machines where Gatekeeper warnings are acceptable.

```bash
./scripts/package_unsigned.sh
```

The script builds the Release app without signing and creates a zip in `dist/`.

## Before public distribution

Replace the placeholder Bundle ID:

```text
com.example.DeepSeekBalanceBar
```

with a real reverse-DNS identifier, for example:

```text
com.yourcompany.DeepSeekBalanceBar
```

Then set the Apple Developer Team in Xcode and create a signed archive:

1. Open `DeepSeekBalanceBar.xcodeproj`.
2. Select the `DeepSeekBalanceBar` target.
3. Open `Signing & Capabilities`.
4. Set `Team`.
5. Set a real `Bundle Identifier`.
6. Use `Product > Archive`.
7. Export the archive with Developer ID signing for outside-App-Store distribution.
8. Notarize the exported app or disk image before sharing publicly.

## Release checklist

- Confirm API key save, reload, logout, and Keychain deletion.
- Confirm refresh and error states with a valid and invalid API key.
- Confirm launch at login can be enabled and disabled.
- Confirm the app starts as a menu bar item only.
- Confirm the package opens on a clean macOS 14+ user account.
- Confirm final package is Developer ID signed and notarized.

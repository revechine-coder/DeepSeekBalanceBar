# DeepSeekBalanceBar

A macOS menu bar app for checking DeepSeek balance and usage.

## Features

- Check DeepSeek account balance
- View usage statistics
- API key stored in macOS Keychain
- Run as a menu bar app
- Optional launch at login

## Requirements

- macOS 14.0 or later

## Install

1. Download `DeepSeekBalanceBar-1.0-unsigned.zip` from [Releases](https://github.com/revechine-coder/DeepSeekBalanceBar/releases)
2. Unzip it
3. Move `DeepSeekBalanceBar.app` to `/Applications`
4. If macOS blocks the first launch, allow it from System Settings

> This build is currently unsigned/ad-hoc signed and intended for trusted testing. For wider public distribution, a Developer ID signed and notarized build is recommended.

## Privacy

API key is stored locally in macOS Keychain. The app only talks to DeepSeek API endpoints needed for balance and usage queries.

## Build from Source

```bash
./scripts/package_unsigned.sh
```

## License

Not specified yet.

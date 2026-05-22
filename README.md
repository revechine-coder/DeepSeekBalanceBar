# DeepSeekBalanceBar

A macOS menu bar app for checking DeepSeek balance and usage. / 一款用于查询 DeepSeek 余额和使用情况的 macOS 菜单栏应用。

[English](#english) | [中文](#chinese)

---

<a name="chinese"></a>

## 中文介绍

一款用于检查 DeepSeek 账户余额和使用额度的 macOS 菜单栏应用。

### 功能特性

- 检查 DeepSeek 账户余额
- 查看使用额度统计
- API 密钥安全存储在本地 Mac 中
- 常驻菜单栏，方便随时查看
- 支持开机自启动设置

### 系统要求

- macOS 14.0 或更高版本

### 安装指南

1. 从 [Releases](https://github.com/revechine-coder/DeepSeekBalanceBar/releases) 下载最新版的 `DeepSeekBalanceBar-1.0-unsigned.zip`
2. 解压压缩包
3. 将 `DeepSeekBalanceBar.app` 拖入 `/Applications` (应用程序) 文件夹
4. 如果首次启动被 macOS 拦截，请前往“系统设置 -> 隐私与安全性”允许其运行

> 提示：目前该构建版本是未签名/临时签名的，仅用于受信测试。如果需要更广泛的分发，建议使用具有 Developer ID 签名并经过公证的构建版本。

### 隐私说明

API 密钥通过应用偏好设置安全地存储在您的 Mac 本地。应用仅与 DeepSeek 官方 API 接口进行通信以获取余额和使用数据，绝不会外泄。

### 源码编译

```bash
./scripts/package_unsigned.sh
```

### 开源协议

暂未指定。

---

<a name="english"></a>

## English Introduction

A macOS menu bar app designed for checking DeepSeek account balance and real-time usage statistics.

### Features

- Check DeepSeek account balance.
- View real-time usage statistics.
- API key is stored locally and securely on your Mac.
- Runs unobtrusively in the menu bar.
- Optional launch-at-login setting.

### Requirements

- macOS 14.0 or later.

### Install

1. Download `DeepSeekBalanceBar-1.0-unsigned.zip` from [Releases](https://github.com/revechine-coder/DeepSeekBalanceBar/releases).
2. Unzip the package.
3. Move `DeepSeekBalanceBar.app` to your `/Applications` directory.
4. If macOS blocks the first launch, allow it under **System Settings > Privacy & Security**.

> **Note:** This build is currently unsigned/ad-hoc signed and intended for trusted testing. For wider public distribution, a Developer ID signed and notarized build is recommended.

### Privacy

Your API key is stored locally on your Mac using standard app preferences. The app only communicates directly with DeepSeek official API endpoints required for fetching balance and usage metrics.

### Build from Source

```bash
./scripts/package_unsigned.sh
```

### License

Not specified yet.

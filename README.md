# Quick-CLI 🚀

**Quick-CLI** 是一个专为开发者设计的统一命令行管理脚本，旨在为 **Claude Code** 和 **Codex CLI** 提供一个优雅、高效且无闪烁的终端用户界面（TUI）。

[简体中文](#quick-cli-) | [English](#quick-cli-en)


## ✨ 核心特性

- 🛠 **统一管理**：在一个界面中无缝切换和启动 Claude Code 与 Codex CLI。
- ⚡ **零闪烁 TUI**：基于 PowerShell 原子渲染技术，提供静止如水的菜单交互体验。
- 🌍 **全平台支持**：完美适配 Windows、Linux 和 macOS。
- 🌐 **多语言支持**：支持中英文一键切换。
- 🔒 **环境隔离**：自动处理存储隔离与 API 安全配置。


## ⚡ 极速一键安装

请根据你的操作系统选择相应的命令，在终端中粘贴并运行，即可完成自动下载、安装与环境配置：

### 🪟 Windows (PowerShell)
```powershell
powershell -c "irm https://raw.githubusercontent.com/Xiaode-AI/Quick-CLI/main/install.ps1 | iex"
```

### 🍎 macOS / 🐧 Linux (Bash/zsh)
必须已安装 [PowerShell Core](https://github.com/PowerShell/PowerShell)。
```bash
curl -sSL https://raw.githubusercontent.com/Xiaode-AI/Quick-CLI/main/install.ps1 | pwsh
```

---


## 🚀 启动与使用

安装完成后，请**重启你的终端**，然后即可在任何地方通过以下命令启动：

*   **`qc`** (推荐)
*   **`quick`**
*   **`quick-cli`**

> [!TIP]
> **开发者直接运行**：如果你在项目根目录下，也可以直接执行 `.\src\Script.ps1` 启动。


## ⌨️ 快捷键说明

| 按键 | 功能 |
| :--- | :--- |
| **↑ / ↓ / Tab** | 切换当前选项 |
| **Enter** | 确认选择 |
| **1 - N** | 快速跳转到对应编号的选项 |
| **Esc** | 返回上一级菜单 / 取消文本输入 |


## 🎨 自定义指南

- **多语言支持 (i18n)**：你可以编辑 `i18n/` 目录下的 JSON 文件来更改菜单名称或表情符号。
- **配置文件 (config.json)**：提供商信息和模型列表会持久化存储在该文件中。你可以参考 `config.example.json` 进行配置。


---

# Quick-CLI (EN)

**Quick-CLI** is a unified command-line management script designed for developers. It provides an elegant, high-efficiency, flicker-free Terminal User Interface (TUI) for **Claude Code** and **Codex CLI**.


## ✨ Features

- 🛠 **Unified Management**: Seamlessly switch between and launch Claude Code and Codex CLI in one interface.
- ⚡ **Zero-Flicker TUI**: Built with PowerShell atomic rendering technology for a smooth, stable menu experience.
- 🌍 **Cross-Platform**: Optimized for Windows, macOS, and Linux.
- 🌐 **Multi-Language Support**: Easily switch between English and Chinese.
- 🔒 **Environment Isolation**: Automatically handles storage isolation and secure API configurations.


## ⚡ Quick One-Line Install

Choose the command for your OS, paste it into your terminal, and run it to complete automatic download, installation, and environment setup:

### 🪟 Windows (PowerShell)
```powershell
powershell -c "irm https://raw.githubusercontent.com/Xiaode-AI/Quick-CLI/main/install.ps1 | iex"
```

### 🍎 macOS / 🐧 Linux (Bash/zsh)
Must have [PowerShell Core](https://github.com/PowerShell/PowerShell) installed.
```bash
curl -sSL https://raw.githubusercontent.com/Xiaode-AI/Quick-CLI/main/install.ps1 | pwsh
```

---

## 🚀 Launch & Usage

After installation, **restart your terminal**, then launch the tool from anywhere using:

*   **`qc`** (Recommended)
*   **`quick`**
*   **`quick-cli`**

> [!TIP]
> **Run from Source**: If you are in the project root, you can also run `.\src\Script.ps1` directly.


## ⌨️ Shortcuts

| Key | Function |
| :--- | :--- |
| **↑ / ↓ / Tab** | Switch current option |
| **Enter** | Confirm selection |
| **1 - N** | Quickly jump to option by number |
| **Esc** | Back to previous menu / Cancel text input |


## 🎨 Customization Guide

- **Localization (i18n)**: You can edit files in the `i18n/` directory (e.g., `en-us.json`, `zh-cn.json`) to customize menu text or emojis.
- **Configuration (config.json)**: Provider information and model lists are persisted in this file at the root. See `config.example.json` for a template.


## 📜 License

MIT [LICENSE](LICENSE) © 2024 Xiaode-AI

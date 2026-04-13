# Quick-CLI 🚀

**Quick-CLI** 是一个专为开发者设计的统一命令行管理脚本，旨在为 **Claude Code** 和 **Codex CLI** 提供一个优雅、高效且无闪烁的终端用户界面（TUI）。

---

## ✨ 核心特性

- 🛠 **统一管理**：在一个界面中无缝切换和启动 Claude Code 与 Codex CLI。
- ⚡ **零闪烁 TUI**：基于 PowerShell 原子渲染技术，提供静止如水的菜单交互体验。
- 🌍 **全平台支持**：完美适配 Windows、Linux 和 macOS。
- 🔒 **环境隔离**：自动处理存储隔离与 API 安全配置。

---

## ⚡ 极速一键安装

请根据你的操作系统选择相应的命令，在终端中粘贴并运行，即可完成自动下载、安装与环境配置：

### 🪟 Windows (PowerShell)
```powershell
powershell -c "irm https://raw.githubusercontent.com/你的用户名/Quick-CLI/main/install.ps1 | iex"
```

### 🍎 macOS / 🐧 Linux (Bash/zsh)
必须已安装 [PowerShell Core](https://github.com/PowerShell/PowerShell)。
```bash
curl -sSL https://raw.githubusercontent.com/你的用户名/Quick-CLI/main/install.ps1 | pwsh
```

> **注意**：请将 URL 中的 `你的用户名` 替换为你真实的 GitHub 用户名。

---

## 🚀 启动与使用

安装完成后，请**重启你的终端**，然后即可在任何地方通过以下命令启动：

*   **`qc`** (推荐)
*   **`quick`**
*   **`quick-cli`**

---

## ⌨️ 快捷键说明

| 按键 | 功能 |
| :--- | :--- |
| **↑ / ↓ / Tab** | 切换当前选项 |
| **Enter** | 确认选择 |
| **1 - N** | 快速跳转到对应编号的选项 |
| **Esc** | 返回上一级菜单 / 取消文本输入 |

---

## 🎨 自定义指南

- **修改界面文本 (UI.json)**：你可以编辑 `src/UI.json` 来更改菜单名称或表情符号。
- **配置文件 (config.json)**：提供商信息和模型列表会持久化存储在该文件中。

---

## 📜 许可证

本项目按原样提供，仅供学习与提升工作效率使用。

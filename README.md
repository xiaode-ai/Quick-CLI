# Quick-CLI 🚀

**Quick-CLI** 是一个专为开发者设计的统一命令行管理脚本，旨在为 **Claude Code** 和 **Codex CLI** 提供一个优雅、高效且无闪烁的终端用户界面（TUI）。

---

## ✨ 核心特性

- 🛠 **统一管理**：在一个界面中无缝切换和启动 Claude Code 与 Codex CLI。
- ⚡ **零闪烁 TUI**：基于 PowerShell 原子渲染技术，提供静止如水的菜单交互体验。
- 🌍 **逻辑与语言分离**：UI 文本存储在 `UI.json` 中，支持中英文、Emoji 自由定制，绝不乱码。
- 🔒 **环境隔离**：自动处理存储隔离与 API 安全配置。

---

## ⚡ 极速一键安装 (推荐)

在 PowerShell 中复制并运行以下命令，即可完成一键自动下载、安装与环境配置：

```powershell
powershell -c "irm https://raw.githubusercontent.com/你的用户名/Quick-CLI/main/install.ps1 | iex"
```

> **注意**：请将 URL 中的 `你的用户名` 替换为你真实的 GitHub 用户名。

---

## 🛠️ 分步安装设置 (手动)

想要在任何终端、任何地方像调用系统命令一样使用此工具？请按以下步骤操作：

### 1. 克隆本仓库
```powershell
git clone https://github.com/你的用户名/Quick-CLI.git
cd Quick-CLI
```

### 2. 运行一键设置脚本
在 PowerShell 中运行以下命令。它会自动检查你的环境依赖，并为你创建快捷别名：
```powershell
.\setup.ps1
```
> **注意**：如果提示禁止执行脚本，请先运行 `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`。

### 3. 重启并使用
**重启你的终端/PowerShell**。现在，你可以直接在任何地方输入：
*   **`qc`** (PowerShell 推荐)
*   **`quick-cli`** (CMD 或 已设置 Path 环境的环境)

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

- **修改界面文本 (UI.json)**：你可以编辑 `UI.json` 来更改菜单名称或表情符号。
- **配置文件 (config.json)**：提供商信息和模型列表会持久化存储在该文件中。

---

## 📜 许可证

本项目按原样提供，仅供学习与提升工作效率使用。

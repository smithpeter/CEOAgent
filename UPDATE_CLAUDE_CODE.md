# 在 Mac Shell 中更新 Claude Code/Cursor 的方法

## 方法 1: 通过 Homebrew Cask 更新

如果 Cursor 是通过 Homebrew 安装的：

```bash
# 更新 Homebrew 本身
brew update

# 升级 Cursor
brew upgrade --cask cursor

# 或者指定具体应用
brew upgrade --cask cursor
```

## 方法 2: 通过命令行检查版本并更新

```bash
# 检查当前版本（如果已安装 CLI）
cursor --version

# 通过 Homebrew 检查已安装的版本
brew info --cask cursor
```

## 方法 3: 通过 npm/pip 等包管理器

如果 Claude Code 是作为 npm 包安装的：

```bash
# npm 全局更新
npm update -g @anthropic-ai/claude-code
# 或
npm install -g @anthropic-ai/claude-code@latest

# 检查版本
npm list -g @anthropic-ai/claude-code
```

## 方法 4: 重新安装最新版本

```bash
# 通过 Homebrew 重新安装最新版本
brew reinstall --cask cursor

# 或者先卸载再安装
brew uninstall --cask cursor
brew install --cask cursor
```

## 方法 5: 使用 Auto-Update（自动更新）

如果 Cursor 支持自动更新：

```bash
# 在 Cursor 应用内：
# Settings → Updates → Check for Updates
# 或者通过命令行触发更新检查
open -a Cursor && sleep 2 && osascript -e 'tell application "Cursor" to activate'
```

## 检查是否通过 Homebrew 安装

```bash
# 检查是否通过 Homebrew 安装
brew list --cask | grep -i cursor

# 查看所有已安装的 cask
brew list --cask
```

## 注意事项

- 如果 Cursor 是通过官网直接下载安装的 `.dmg` 文件，需要通过应用内更新或重新下载安装包
- 确保你有管理员权限来更新应用程序
- 更新前建议保存所有工作


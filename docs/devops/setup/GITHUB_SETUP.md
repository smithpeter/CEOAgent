# GitHub 仓库设置指南

本指南将帮助你将 CEOAgent 项目上传到 GitHub。

## ✅ 已完成步骤

1. ✅ Git 仓库已初始化
2. ✅ 所有文件已添加到暂存区
3. ✅ 初始提交已创建（提交哈希: `19193ee`）

## 📋 接下来需要做的

### 方法一：使用脚本自动设置（推荐）

1. **运行设置脚本**：
   ```bash
   ./scripts/setup_github.sh <你的GitHub用户名> [仓库名称]
   ```
   
   示例：
   ```bash
   ./scripts/setup_github.sh zouyongming CEOAgent
   ```

2. **在 GitHub 上创建仓库**：
   - 访问 https://github.com/new
   - 仓库名称：`CEOAgent`（或你指定的名称）
   - 描述：`CEO 决策智能体 - 基于 AI 的 CEO 决策支持系统`
   - 选择 Public 或 Private
   - **⚠️ 重要：不要勾选任何初始化选项**（README、.gitignore、license 都不要选）

3. **推送代码**：
   ```bash
   git push -u origin main
   ```

### 方法二：手动设置

1. **在 GitHub 上创建新仓库**：
   - 访问 https://github.com/new
   - 填写仓库信息（名称、描述等）
   - **不要**初始化 README、.gitignore 或 license

2. **添加远程仓库**：
   ```bash
   # 使用 HTTPS
   git remote add origin https://github.com/<你的用户名>/CEOAgent.git
   
   # 或使用 SSH（如果已配置 SSH key）
   git remote add origin git@github.com:<你的用户名>/CEOAgent.git
   ```

3. **验证远程仓库**：
   ```bash
   git remote -v
   ```

4. **推送代码**：
   ```bash
   git push -u origin main
   ```

### 方法三：使用 GitHub CLI（如果已安装）

如果你已经安装了 GitHub CLI (`gh`)，可以使用以下命令：

```bash
# 创建并推送仓库
gh repo create CEOAgent --public --source=. --remote=origin --push

# 或设置为私有仓库
gh repo create CEOAgent --private --source=. --remote=origin --push
```

## 🔐 认证问题

如果推送时遇到认证问题：

### HTTPS 方式
- GitHub 已不再支持密码认证
- 需要使用 **Personal Access Token (PAT)**
- 创建 Token：https://github.com/settings/tokens
- 使用 Token 作为密码推送代码

### SSH 方式（推荐）
1. **检查是否已有 SSH key**：
   ```bash
   ls -al ~/.ssh
   ```

2. **如果没有，生成新的 SSH key**：
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

3. **添加到 SSH agent**：
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```

4. **复制公钥到 GitHub**：
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
   - 然后访问 https://github.com/settings/keys
   - 点击 "New SSH key"
   - 粘贴公钥内容

5. **测试连接**：
   ```bash
   ssh -T git@github.com
   ```

## 📊 推送后检查

推送成功后，你可以：

1. **访问仓库**：
   ```
   https://github.com/<你的用户名>/CEOAgent
   ```

2. **设置仓库描述和标签**：
   - 在 GitHub 仓库页面点击 ⚙️ Settings
   - 添加项目描述
   - 添加 Topics（例如：`ai`, `ceo-agent`, `decision-support`, `python`）

3. **查看 CI/CD**：
   - 项目包含 `.github/workflows/ci-cd.yml`
   - 推送代码后会自动触发 GitHub Actions

## 🛠️ 常用 Git 命令

```bash
# 查看状态
git status

# 查看提交历史
git log --oneline

# 查看远程仓库
git remote -v

# 拉取远程更新
git pull origin main

# 推送代码
git push origin main
```

## ❓ 常见问题

### Q: 推送时提示 "remote origin already exists"
A: 使用以下命令更新远程仓库地址：
```bash
git remote set-url origin <新的仓库地址>
```

### Q: 推送时提示 "Authentication failed"
A: 检查你的认证方式，确保使用 Personal Access Token（HTTPS）或 SSH key（SSH）

### Q: 想更改仓库名称
A: 在 GitHub 仓库设置中重命名，然后更新本地远程地址：
```bash
git remote set-url origin <新的仓库地址>
```

## 📝 下一步

项目上传成功后，建议：

1. ✅ 设置仓库描述和标签
2. ✅ 完善 README.md（如果需要）
3. ✅ 设置分支保护规则（Settings → Branches）
4. ✅ 配置 GitHub Actions Secrets（如果需要 CI/CD）
5. ✅ 邀请协作者（如果需要）

---

**提示**：如果需要帮助，运行 `./scripts/setup_github.sh` 查看详细说明。

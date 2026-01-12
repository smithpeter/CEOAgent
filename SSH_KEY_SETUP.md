# SSH Key 配置完成

## ✅ 已完成

1. ✅ SSH key 已生成：`~/.ssh/id_ed25519_github`
2. ✅ SSH config 已配置
3. ✅ Key 已添加到 ssh-agent

## 📋 下一步：将公钥添加到 GitHub

### 公钥内容（请复制以下内容）：

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMaFT3++QBa1vIEw7eyZUaPEwc7I56sA3s3I1nq9r7xe smithpeter@github
```

### 添加到 GitHub 的步骤：

1. **访问 SSH Keys 设置页面**：
   https://github.com/settings/keys

2. **点击 "New SSH key"** 按钮

3. **填写表单**：
   - **Title**: 填写一个描述（例如：`MacBook Pro` 或 `CEOAgent Dev`）
   - **Key type**: 选择 `Authentication Key`
   - **Key**: 粘贴上面的公钥内容（从 `ssh-ed25519` 开始到 `smithpeter@github` 结束）

4. **点击 "Add SSH key"**

5. **测试连接**（添加后运行）：
   ```bash
   ssh -T git@github.com
   ```
   如果成功，你会看到类似这样的消息：
   ```
   Hi smithpeter! You've successfully authenticated, but GitHub does not provide shell access.
   ```

## 🔄 切换远程仓库为 SSH

添加 SSH key 到 GitHub 后，运行以下命令切换远程仓库：

```bash
git remote set-url origin git@github.com:smithpeter/CEOAgent.git
```

然后就可以使用 SSH 方式推送代码了，不需要输入密码或 token！

## 📝 常用命令

```bash
# 查看远程仓库
git remote -v

# 切换为 SSH（在添加 SSH key 到 GitHub 后）
git remote set-url origin git@github.com:smithpeter/CEOAgent.git

# 切换为 HTTPS（如果需要）
git remote set-url origin https://github.com/smithpeter/CEOAgent.git

# 测试 SSH 连接
ssh -T git@github.com

# 查看 SSH key
cat ~/.ssh/id_ed25519_github.pub
```

---

**提示**：添加 SSH key 后，记得切换到 SSH 方式再推送代码。

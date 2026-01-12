# 自动推送配置说明

本项目已配置自动推送功能，每次执行 `git commit` 后会自动推送到远程仓库（GitHub）。

## ✅ 功能特性

- ✅ **自动推送**: 每次 commit 后自动执行 `git push`
- ✅ **智能检测**: 只在有远程仓库时推送，避免错误
- ✅ **分支跟踪**: 自动推送到当前分支对应的远程分支
- ✅ **临时禁用**: 可以通过环境变量临时跳过自动推送
- ✅ **错误处理**: 推送失败时会提示手动推送

## 📋 使用方法

### 正常使用（自动推送）

```bash
# 修改文件后
git add .
git commit -m "你的提交信息"
# 提交后会自动推送，无需手动运行 git push
```

### 临时跳过自动推送

如果需要临时禁用自动推送（比如一次性提交多个 commit，只推送一次）：

```bash
SKIP_AUTO_PUSH=true git commit -m "提交信息"
```

或者：

```bash
export SKIP_AUTO_PUSH=true
git commit -m "提交1"
git commit -m "提交2"
# ... 更多提交
unset SKIP_AUTO_PUSH  # 取消禁用
git push  # 最后手动推送一次
```

## 🔧 管理自动推送 Hook

### 重新安装 Hook

如果 hook 文件丢失或需要重新安装：

```bash
./scripts/install-auto-push.sh
```

### 卸载自动推送

如果不想使用自动推送功能：

```bash
./scripts/uninstall-auto-push.sh
```

### 手动查看 Hook

Hook 文件位置：`.git/hooks/post-commit`

查看内容：
```bash
cat .git/hooks/post-commit
```

## 📝 工作原理

自动推送通过 Git 的 `post-commit` hook 实现：

1. **触发时机**: 每次 `git commit` 成功后
2. **执行流程**:
   - 获取当前分支名
   - 检查是否配置了远程仓库
   - 检查是否设置了跳过标志
   - 执行 `git push origin <当前分支>`
   - 显示推送结果

## ⚠️ 注意事项

1. **网络要求**: 自动推送需要网络连接，如果网络不稳定可能推送失败
2. **推送失败**: 如果推送失败，hook 会提示你手动运行 `git push`
3. **分支保护**: 如果远程分支有保护规则，推送可能失败（需要 pull request）
4. **冲突处理**: 如果有冲突，需要先 `git pull` 解决冲突后再提交

## 🔍 故障排除

### 推送失败怎么办？

如果自动推送失败，你可以：

1. **查看错误信息**: Hook 会显示错误信息
2. **手动推送**: 运行 `git push` 手动推送
3. **检查远程仓库**: 运行 `git remote -v` 确认远程仓库配置正确
4. **检查 SSH/HTTPS**: 确认认证方式配置正确

### 不想使用自动推送？

使用卸载脚本：

```bash
./scripts/uninstall-auto-push.sh
```

### Hook 没有执行？

检查 hook 文件权限：

```bash
ls -l .git/hooks/post-commit
```

确保有执行权限，如果没有：

```bash
chmod +x .git/hooks/post-commit
```

## 🎯 最佳实践

1. **小步提交**: 推荐频繁提交小改动，利用自动推送保持远程仓库同步
2. **提交前检查**: 提交前使用 `git status` 检查要提交的文件
3. **清晰的提交信息**: 使用清晰的提交信息，便于版本管理
4. **定期备份**: 虽然自动推送，但建议定期备份重要数据

## 📚 相关文档

- [Git Hooks 文档](https://git-scm.com/docs/githooks)
- [Git Push 文档](https://git-scm.com/docs/git-push)
- [GitHub 推送指南](./GITHUB_SETUP.md)

---

**提示**: 自动推送功能是可选的，如果不需要可以随时卸载。

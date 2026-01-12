# GitHub Secrets 快速配置指南

## 📋 配置步骤

### 步骤 1: 打开 GitHub Secrets 页面

**访问以下链接：**
```
https://github.com/smithpeter/CEOAgent/settings/secrets/actions
```

或点击：**仓库 Settings → Secrets and variables → Actions → New repository secret**

---

### 步骤 2: 添加 5 个 Secrets（逐个添加）

点击 **"New repository secret"**，然后添加以下内容：

---

#### Secret 1: SERVER_IP

- **Name**: `SERVER_IP`
- **Secret**: 
```
136.115.199.54
```

点击 **Add secret**

---

#### Secret 2: SERVER_USER

- **Name**: `SERVER_USER`
- **Secret**: 
```
zouyongming
```

点击 **Add secret**

---

#### Secret 3: SERVER_SSH_PORT

- **Name**: `SERVER_SSH_PORT`
- **Secret**: 
```
22
```

点击 **Add secret**

---

#### Secret 4: SERVER_DEPLOY_PATH

- **Name**: `SERVER_DEPLOY_PATH`
- **Secret**: 
```
/opt/ceoagent
```

点击 **Add secret**

---

#### Secret 5: SERVER_SSH_PRIVATE_KEY

- **Name**: `SERVER_SSH_PRIVATE_KEY`
- **Secret**: （完整复制下面的私钥内容，包括 BEGIN 和 END 行）

```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACC6CebU8tdY3qj4vjRWqfLQ+4SFL1y1mLa5rh+p0DinpAAAAJgZHlc8GR5X
PAAAAAtzc2gtZWQyNTUxOQAAACC6CebU8tdY3qj4vjRWqfLQ+4SFL1y1mLa5rh+p0DinpA
AAAEAQbLp7XTs1lw72KMSC2mrDSWPlRGOLKdLXVyUtN5/MaboJ5tTy11jeqPi+NFap8tD7
hIUvXLWYtrmuH6nQOKekAAAAD2Nlb2FnZW50LWRlcGxveQECAwQFBg==
-----END OPENSSH PRIVATE KEY-----
```

**⚠️ 重要提示：**
- 必须完整复制，包括 `-----BEGIN OPENSSH PRIVATE KEY-----` 和 `-----END OPENSSH PRIVATE KEY-----`
- 不能有多余的空格或换行

点击 **Add secret**

---

### 步骤 3: 验证配置

添加完所有 5 个 Secrets 后，你应该看到：

- ✅ SERVER_IP
- ✅ SERVER_USER
- ✅ SERVER_SSH_PORT
- ✅ SERVER_DEPLOY_PATH
- ✅ SERVER_SSH_PRIVATE_KEY

---

## ✅ 配置完成！

配置完成后，可以测试自动部署：

```bash
git commit --allow-empty -m "测试自动部署"
git push origin main
```

然后访问：https://github.com/smithpeter/CEOAgent/actions 查看部署状态。

---

## 📋 快速参考

**GitHub Secrets 页面：**
https://github.com/smithpeter/CEOAgent/settings/secrets/actions

**查看部署状态：**
https://github.com/smithpeter/CEOAgent/actions

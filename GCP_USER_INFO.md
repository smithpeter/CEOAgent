# GCP 服务器用户信息

## 服务器信息

- **IP 地址**: 136.115.199.54
- **用户名**: zouyongming（不是 root）
- **SSH 端口**: 22
- **云服务商**: Google Cloud Platform (GCP)
- **地区**: 沙特

## SSH 公钥格式

在 GCP Console 添加 SSH 公钥时，使用以下格式：

```
zouyongming:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoJ5tTy11jeqPi+NFap8tD7hIUvXLWYtrmuH6nQOKek ceoagent-deploy
```

**重要**：格式是 `用户名:公钥内容`，用户名是 `zouyongming`。

## 连接命令

```bash
ssh -i ~/.ssh/ceoagent_deploy zouyongming@136.115.199.54
```

## GitHub Secrets 配置

配置 GitHub Secrets 时：

- `SERVER_USER`: `zouyongming`
- `SERVER_IP`: `136.115.199.54`
- `SERVER_SSH_PORT`: `22`
- `SERVER_DEPLOY_PATH`: `/opt/ceoagent`
- `SERVER_SSH_PRIVATE_KEY`: (私钥内容)

## 部署脚本默认用户

所有部署脚本已更新为默认使用 `zouyongming` 用户。

# VLESS + REALITY 一键部署工具

双击 `setup.bat`，全程自动。你只需要一台海外 VPS。

---

## 使用方法

### 前期准备

1. 买一台海外 VPS（推荐香港，dogyun、搬瓦工等）
2. 记下服务器的 **IP 地址** 和 **root 密码**

### 一键部署

双击 **`setup.bat`**，按提示输入 IP 和密码，等 1-2 分钟即可。

脚本会自动完成：

1. 检查/安装 Node.js
2. 连接你的服务器
3. 安装 xray（服务端）
4. 生成 VLESS + REALITY 密钥
5. 配置并启动服务
6. 下载/配置 v2rayN（客户端）
7. 自动启动 v2rayN

### 配置浏览器翻墙

1. **打开 Edge/Chrome 浏览器**
2. **搜索安装 SwitchyOmega 插件**
3. **新建代理配置**：
   - 协议：SOCKS5
   - 服务器：127.0.0.1
   - 端口：10808
4. 点击插件图标，切换到此配置即可翻墙

---

## 文件说明

| 文件 | 用途 |
|---|---|
| `setup.bat` | **入口**，双击运行 |
| `start.ps1` | 部署流程脚本 |
| `server/deploy.js` | SSH 部署服务端 |
| `scripts/diagnose.ps1` | 诊断检查工具 |
| `templates/config-template.json` | 配置模板 |

---

## 常见问题

**Q: 需要先装 Node.js 吗？**
A: 不需要，脚本会自动安装。

**Q: 没有 VPS 怎么办？**
A: 去 dogyun、搬瓦工等网站购买，一个月几十块钱。

**Q: 部署失败怎么办？**
A: 检查 IP 和密码是否正确，服务器是否已开机。重新运行 `setup.bat` 再试一次。

**Q: v2rayN 下载失败怎么办？**
A: 手动下载 https://github.com/2dust/v2rayN/releases ，解压到 `v2rayN-windows-64` 文件夹，重新运行 `setup.bat`。

**Q: 怎么查看配置参数？**
A: 部署完成后，`output/v2rayN-config.json` 文件里有完整参数。

---

- GitHub: https://github.com/xiao768108/v2rayN-quickstart
- Gitee（国内访问）: https://gitee.com/xiaoyaoyou08/v2rayN-quickstart
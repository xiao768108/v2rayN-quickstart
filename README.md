# v2rayN 一键部署工具

买台海外服务器，双击一个文件，输入 IP 和密码，等 2 分钟。

不需要懂技术，不需要装任何软件。

---

## 快速开始

### 1. 下载

国内用户：[Gitee 下载](https://gitee.com/xiaoyaoyou08/v2rayN-quickstart/releases/download/v1.1.0/deploy.exe)

国外用户：[GitHub 下载](https://github.com/xiao768108/v2rayN-quickstart/releases/download/v1.1.0/deploy.exe)

只有一个文件 `deploy.exe`，4MB。

### 2. 运行

双击 `deploy.exe`，按提示输入：

- 服务器 IP
- root 密码

等 1-2 分钟，自动完成。

### 3. 使用

打开浏览器，装 SwitchyOmega 插件，新建一个配置：

| 字段 | 值 |
|---|---|
| 协议 | SOCKS5 |
| 服务器 | 127.0.0.1 |
| 端口 | 10808 |

---

## 准备工作

你需要一台海外服务器（香港延迟最低）。推荐：

- dogyun
- 搬瓦工
- Vultr

最低配置 1 核 / 512MB 内存 / 10GB 硬盘就够了，系统选 CentOS 7 或 Ubuntu 20+。

---

## 原理

这个工具会自动在你的服务器上部署 xray，配置 VLESS + REALITY 协议。部署完成后，本机 v2rayN 会通过安全加密通道连接到你的服务器。

- 传输协议使用 VLESS，轻量高效
- 连接使用 REALITY 技术，流量特征与普通 HTTPS 无异

---

## 常见问题

**需要先装 Node.js 吗？**
不需要。deploy.exe 是编译好的单文件，双击就能用。

**需要预先准备什么？**
一台海外服务器和它的 root 密码。

**部署失败了怎么办？**
检查 IP 和密码是否正确，服务器是否已开机。重新运行 deploy.exe 再试。

**想查看或修改源码？**
仓库里也有 `setup.bat` + Node.js 版本，方便二次开发。

---

- GitHub: https://github.com/xiao768108/v2rayN-quickstart
- Gitee: https://gitee.com/xiaoyaoyou08/v2rayN-quickstart
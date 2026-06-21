# v2rayN 一键搭建工具

买台海外 VPS，双击一个文件，输入 IP 和密码，等 2 分钟就有梯子了。

不需要懂技术，不需要装任何软件。

---

## 快速开始

### 1. 下载

**国内用户（推荐）**：[Gitee 下载](https://gitee.com/xiaoyaoyou08/v2rayN-quickstart/releases/download/v1.1.0/deploy.exe)

**国外用户**：[GitHub 下载](https://github.com/xiao768108/v2rayN-quickstart/releases/download/v1.1.0/deploy.exe)

只有一个文件 `deploy.exe`，4MB。

### 2. 运行

双击 `deploy.exe`，按提示输入：

- 服务器 IP
- root 密码

等 1-2 分钟，自动完成。

### 3. 浏览器翻墙

装 SwitchyOmega 插件，新建代理配置：

| 字段 | 值 |
|---|---|
| 协议 | SOCKS5 |
| 服务器 | 127.0.0.1 |
| 端口 | 10808 |

---

## 准备工作

你需要一台海外 VPS（香港的最好）。推荐：

- dogyun — 性价比高，香港节点
- 搬瓦工 — 稳定
- Vultr — 按小时计费

配置要求很低：1 核 / 512MB 内存 / 10GB 硬盘就够。

---

## 原理

```
你的电脑 (deploy.exe) → SSH → 海外 VPS (安装 xray)
                               ↓
                    生成 VLESS + REALITY 配置
                               ↓
                    浏览器 → SwitchyOmega → v2rayN → 海外服务器 → 外网
```

- **VLESS**：传输协议，加密通信
- **REALITY**：伪装技术，流量看起来像访问微软官网，GFW 无法识别

---

## 常见问题

**需要先装 Node.js 吗？**
不需要。deploy.exe 是编译好的单文件，双击就能用。

**需要先有梯子吗？**
不需要。deploy.exe 通过 SSH 连接你的服务器（在香港），服务器帮你安装一切。

**部署失败了怎么办？**
检查 IP 和密码是否正确，服务器是否已开机。重新运行 deploy.exe 再试。

**想用脚本方式（源码可见）？**
仓库里也有 `setup.bat` + Node.js 版本，方便你查看和修改源码。

---

- GitHub: https://github.com/xiao768108/v2rayN-quickstart
- Gitee: https://gitee.com/xiaoyaoyou08/v2rayN-quickstart
# VLESS + REALITY 一键部署工具

从零搭建自己的翻墙服务器，全程自动化。只需一台海外 VPS，一条命令搞定。

---

## 目录

- [原理](#原理)
- [准备工作](#准备工作)
- [一键部署服务端](#一键部署服务端)
- [配置客户端](#配置客户端)
- [浏览器翻墙设置](#浏览器翻墙设置)
- [关键词解释](#关键词解释)
- [常见问题](#常见问题)

---

## 原理

```
你的电脑 (v2rayN) → 海外 VPS (xray) → 目标网站
  VLESS + REALITY       伪装成访问微软
```

**VLESS**：轻量传输协议，负责加密通信。
**REALITY**：下一代 TLS 伪装技术，你的流量看起来只是在访问 `www.microsoft.com`，GFW 无法识别。

## 准备工作

### 1. 一台海外 VPS

推荐配置（够用即可）：

| 配置 | 建议 |
|---|---|
| CPU | 1 核 |
| 内存 | 512MB |
| 硬盘 | 10GB |
| 流量 | 500GB/月+ |
| 系统 | CentOS 7 / Ubuntu 20.04+ / Debian 11+ |
| 位置 | 香港 / 日本 / 新加坡（延迟最低） |

推荐商家：
- **dogyun**（香港，性价比高）
- **搬瓦工**（稳定）
- **Vultr**（按小时计费）

### 2. 本机环境

- Windows 10/11
- Node.js（[下载地址](https://nodejs.org/)）
- PowerShell

## 一键部署服务端

### 安装依赖

```powershell
cd v2rayN-quickstart
npm install
```

### 部署到服务器

```powershell
node server/deploy.js <服务器IP> <root密码>
```

示例：
```powershell
node server/deploy.js 1.2.3.4 MyRootPassword123
```

脚本自动完成：
1. SSH 连接服务器
2. 安装 xray
3. 生成 REALITY 密钥对
4. 配置 VLESS + REALITY（443 端口，伪装 www.microsoft.com）
5. 启动 xray 并设为开机自启
6. 输出所有配置参数
7. 自动生成 v2rayN 配置文件

### 手动配置（无法自动 SSH 时）

如果自动部署失败，可以手动操作：

**第 1 步：SSH 登录服务器**
```bash
ssh root@你的服务器IP
```

**第 2 步：安装 xray**
```bash
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
```

**第 3 步：生成密钥**
```bash
xray x25519
```
记下输出的 `Private key` 和 `Public key`。

**第 4 步：创建配置文件**
```bash
cat > /usr/local/etc/xray/config.json << 'EOF'
{
  "log": { "loglevel": "warning" },
  "inbounds": [{
    "port": 443,
    "protocol": "vless",
    "settings": {
      "clients": [{ "id": "你的UUID", "flow": "xtls-rprx-vision-udp443", "email": "t@t.tt" }],
      "decryption": "none",
      "fallbacks": []
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "dest": "www.microsoft.com:443",
        "serverNames": ["www.microsoft.com"],
        "privateKey": "上一步生成的PrivateKey",
        "shortIds": ["6位随机十六进制"]
      }
    }
  }],
  "outbounds": [
    { "protocol": "freedom", "tag": "direct" },
    { "protocol": "blackhole", "tag": "blocked" }
  ]
}
EOF
```

**第 5 步：启动服务**
```bash
systemctl restart xray
systemctl enable xray
```

**第 6 步：在本地生成客户端配置**
```powershell
node scripts/generate-config.js <服务器IP> <UUID> <PublicKey> <ShortId>
```

## 配置客户端

### 下载 v2rayN

```powershell
.\scripts\download-v2rayn.ps1
```

或从 [GitHub Releases](https://github.com/2dust/v2rayN/releases) 手动下载。

### 应用配置

部署脚本会自动生成 `v2rayN-config.json`，只需：

1. 解压/下载 v2rayN
2. 把 `v2rayN-config.json` 复制到 `v2rayN-windows-64\binConfigs\config.json`
3. 运行 v2rayN.exe
4. 右键节点 → 测试真连接延迟 → 确认绿灯

### 手动填配置（如果自动生成失败）

打开 v2rayN → 服务器 → 添加 [VLESS 服务器]，对照填：

| 字段 | 值 |
|---|---|
| 地址 (Address) | 你的服务器 IP |
| 端口 (Port) | 443 |
| 用户ID (UUID) | 生成的 UUID |
| 传输协议 (network) | raw |
| 伪装类型 (security) | reality |
| 伪装域名 (serverName) | www.microsoft.com |
| 公钥 (publicKey) | 服务器上生成的 |
| ShortId | 生成的 6 位十六进制 |
| 指纹 (fingerprint) | chrome |
| 流控 (flow) | xtls-rprx-vision-udp443 |

## 浏览器翻墙设置

推荐配合 **SwitchyOmega** 浏览器插件，不修改系统代理。

### 安装 SwitchyOmega

- Chrome：Chrome 网上应用店搜索 "SwitchyOmega"
- Edge：扩展商店搜索 "Proxy SwitchyOmega 3"

### 新建代理配置

1. 点插件图标 → 选项
2. 新建情景模式 → 代理服务器
3. 填写：

| 字段 | 值 |
|---|---|
| 协议 | SOCKS5 |
| 服务器 | 127.0.0.1 |
| 端口 | 10808 |

4. 左侧点"应用选项"保存

### 使用方法

- 点击 SwitchyOmega 图标
- 切到刚建的配置 → 浏览器翻墙
- 切回"直接连接" → 国内直连

## 关键词解释

| 术语 | 说明 |
|---|---|
| **VPS** | 虚拟专用服务器，就是你买的海外服务器 |
| **v2rayN** | Windows 客户端，你电脑上运行的翻墙软件 |
| **xray** | 服务端软件，跑在你的 VPS 上 |
| **VLESS** | 传输协议，v2rayN 和 xray 之间通信的语言 |
| **REALITY** | 伪装技术，让流量看起来像访问微软官网 |
| **SNI** | TLS 握手时的域名，这里伪装成 `www.microsoft.com` |
| **UUID** | 你的身份标识，相当于密码 |
| **PublicKey/PrivateKey** | REALITY 的密钥对，服务端生成 |
| **SOCKS5** | 本地代理协议，v2rayN 用这个暴露端口 |
| **SwitchyOmega** | 浏览器插件，控制浏览器走不走代理 |

## 常见问题

### Q: 需要每次开机都手动启动 v2rayN 吗？
A: 可以设置开机自启：v2rayN → 设置 → 参数设置 → 开机自动运行。

### Q: 能跟机场订阅一起用吗？
A: 可以，VPS 自建和机场订阅互不冲突，v2rayN 里可以同时添加多个节点。

### Q: VPS 被封了怎么办？
A: REALITY 协议伪造成微软流量，极难被封。如果真的被封，换一台 VPS 重新部署即可。

### Q: 一个人用够用吗？
A: 1 核 512MB 的 VPS 可以稳定支持几十个人同时使用。

### Q: 部署脚本安全吗？
A: 脚本开源的，可以看到所有代码。SSH 连接仅在本地执行，密码不会被上传到第三方。

---

> **免责声明**：本工具仅供技术学习和研究，请遵守当地法律法规。

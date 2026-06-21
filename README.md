# v2rayN 一键搭建

买台海外服务器，下载两个文件，双击 setup.ps1，输入 IP 和密码，等几分钟。

---

## 使用步骤

**1. 下载**
- 点右上角绿色 Code → Download ZIP
- 在 Releases 里下载 deploy.exe
- 解压 ZIP，把 deploy.exe 放到解压后的文件夹里

**2. 准备**
- 买一台海外 VPS（香港的延迟最低）
- 拿到服务器的 IP 地址 和 root 密码

**3. 运行**
- 右键 setup.ps1 → 使用 PowerShell 运行
- 输入 IP 和密码
- 等几分钟，自动完成

**4. 浏览器翻墙**
- 装 SwitchyOmega 插件
- 新建配置：SOCKS5 / 127.0.0.1 / 10808
- 点击插件图标切换

---

## 下载地址

国内（推荐）：https://gitee.com/xiaoyaoyou08/v2rayN-quickstart/releases/tag/v1.2.0
国外：https://github.com/xiao768108/v2rayN-quickstart/releases/tag/v1.2.0

---

## 原理

用 deploy.exe 在你的服务器上安装 xray，配置 VLESS + REALITY 协议，流量特征与普通 HTTPS 无异。setup.ps1 会自动下载并配置 v2rayN 客户端。

## 常见问题

**需要先装什么吗？**
不需要。setup.ps1 会自动处理一切。

**需要先有梯子吗？**
不需要。服务器在香港，脚本通过 SSH 直接操作。

**部署失败？**
检查 IP 和密码是否正确，服务器是否已开机。重试即可。
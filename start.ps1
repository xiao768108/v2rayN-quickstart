param()

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  VLESS + REALITY 一键部署工具" -ForegroundColor Cyan
Write-Host "  纯新手友好版（无需梯子，全自动）" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

sp = PSScriptRoot

# ─── 1. 检查/安装 Node.js ──────────────────────────────
try {
  nv = node --version 2>$null
  if (-not nv) { throw "not found" }
  Write-Host "[OK] Node.js nv" -ForegroundColor Green
} catch {
  Write-Host "[..] 未检测到 Node.js，尝试自动安装..." -ForegroundColor Yellow
  # 从国内镜像下载 Node.js
  nodeUrl = "https://npmmirror.com/mirrors/node/latest/win-x64/node.exe"
  nodePath = "sp\node_modules\node.exe"
  mkdir "sp\node_modules" -Force | Out-Null
  try {
    Invoke-WebRequest -Uri nodeUrl -OutFile nodePath -TimeoutSec 60 -ErrorAction Stop
    Write-Host "[OK] Node.js 已下载" -ForegroundColor Green
    env:Path += ";sp\node_modules"
  } catch {
    Write-Host "[!] 自动安装失败，手动下载: https://nodejs.org" -ForegroundColor Red
    pause; exit 1
  }
}

# ─── 2. 安装 npm 依赖（使用国内镜像）──────────────────
if (-not (Test-Path "sp\node_modules\ssh2")) {
  Write-Host "[..] 安装依赖..." -ForegroundColor Yellow
  pushd "sp"
  npm init -y 2>$null | Out-Null
  npm install ssh2 --registry https://registry.npmmirror.com 2>$null | Out-Null
  popd
}
Write-Host "[OK] 依赖就绪" -ForegroundColor Green
Write-Host ""

# ─── 3. 输入服务器信息 ──────────────────────────────────
ip = Read-Host "输入服务器 IP"
pw = Read-Host -AsSecureString "输入 root 密码"
plainPw = [System.Net.NetworkCredential]::new("", pw).Password

# ─── 4. 部署到服务器 ────────────────────────────────────
Write-Host ""
Write-Host "[..] 部署中，请稍等..." -ForegroundColor Yellow
Write-Host ""
pushd "sp"
node server/deploy.js ip plainPw 2>&1
if (LASTEXITCODE -ne 0) {
  Write-Host "[!] 部署失败" -ForegroundColor Red
  pause; exit 1
}
popd

# ─── 5. 下载 v2rayN（国内镜像优先）────────────────────
vDir = "sp\v2rayN-windows-64"
vExe = "vDir\v2rayN.exe"
if (-not (Test-Path vExe)) {
  Write-Host "[..] 下载 v2rayN..." -ForegroundColor Yellow

  # 获取最新版本号
  try {
    tag = (Invoke-RestMethod -Uri "https://ghproxy.com/https://api.github.com/repos/2dust/v2rayN/releases/latest" -TimeoutSec 15 -ErrorAction Stop).tag_name
  } catch {
    tag = ""
  }

  if (tag) {
    urls = @(
      "https://ghproxy.com/https://github.com/2dust/v2rayN/releases/download/tag/v2rayN-tag.zip",
      "https://mirror.ghproxy.com/https://github.com/2dust/v2rayN/releases/download/tag/v2rayN-tag.zip"
    )
  } else {
    urls = @(
      "https://ghproxy.com/https://github.com/2dust/v2rayN/releases/latest/download/v2rayN-Core.zip"
    )
  }

  ok = false
  foreach (url in urls) {
    try {
      Write-Host "  下载中..." -ForegroundColor DarkGray
      zip = "env:TEMP\v2rayN.zip"
      Invoke-WebRequest -Uri url -OutFile zip -TimeoutSec 120 -ErrorAction Stop
      Expand-Archive zip -DestinationPath vDir -Force -ErrorAction Stop
      Remove-Item zip -Force -ErrorAction SilentlyContinue
      ok = true
      Write-Host "[OK] v2rayN 下载完成" -ForegroundColor Green
      break
    } catch {
      Write-Host "  重试其他源..." -ForegroundColor DarkGray
    }
  }

  if (-not ok) {
    Write-Host "[!] 下载失败，请手动下载 v2rayN.exe 放到:" -ForegroundColor Yellow
    Write-Host "    vDir" -ForegroundColor Yellow
  }
} else {
  Write-Host "[OK] v2rayN 已存在" -ForegroundColor Green
}

# ─── 6. 复制配置并启动 ──────────────────────────────────
cfg = "sp\output\v2rayN-config.json"
dst = "vDir\binConfigs\config.json"
if (Test-Path cfg) {
  mkdir "vDir\binConfigs" -Force | Out-Null
  Copy-Item cfg dst -Force
  Write-Host "[OK] 配置已应用" -ForegroundColor Green
}

if (Test-Path vExe) {
  Start-Process vExe
  Write-Host "[OK] v2rayN 已启动" -ForegroundColor Green
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "  部署完成！" -ForegroundColor Green
Write-Host "  v2rayN 已启动，右下角托盘找它" -ForegroundColor Green
Write-Host "  浏览器装 SwitchyOmega 填 SOCKS5 127.0.0.1:10808" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
pause
